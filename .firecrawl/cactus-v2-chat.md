#include "../cactus\_engine.h"

#include
#include
#include
#include
#include
#include
#include
#include
#include
#include
#include
#include
#include
#include

#ifdef HAVE\_SDL2
#include
#include
#endif

namespace {

constexpr int kMaxTokens = 1024;
constexpr size\_t kResponseBufferSize = kMaxTokens \* 128;

#ifdef HAVE\_SDL2
constexpr int kRecordSampleRate = 16000;

struct RecordState {
 std::mutex mutex;
 std::vector buffer;
 std::atomic recording{false};
 int actual\_sample\_rate = kRecordSampleRate;
 SDL\_AudioFormat actual\_format = AUDIO\_S16LSB;
 int actual\_channels = 1;
};

RecordState g\_record;

void record\_callback(void\*, Uint8\* stream, int len) {
 if (!g\_record.recording) return;
 std::lock\_guard lock(g\_record.mutex);
 g\_record.buffer.insert(g\_record.buffer.end(), stream, stream + len);
}

std::vector decode\_sdl\_audio\_to\_mono\_f32(const std::vector& input,
 SDL\_AudioFormat format,
 int channels) {
 if (input.empty() \|\| channels <= 0) return {};

 size\_t bytes\_per\_sample = SDL\_AUDIO\_BITSIZE(format) / 8;
 if (bytes\_per\_sample == 0) return {};
 size\_t frame\_count = input.size() / (bytes\_per\_sample \* static\_cast(channels));
 std::vector mono(frame\_count);

 auto sample\_at = \[&\](size\_t sample\_index) -> float {
 const uint8\_t\* p = input.data() + sample\_index \* bytes\_per\_sample;
 switch (format) {
 case AUDIO\_S16LSB: {
 int16\_t v;
 std::memcpy(&v, p, sizeof(v));
 return static\_cast(v) / 32768.0f;
 }
 case AUDIO\_U16LSB: {
 uint16\_t v;
 std::memcpy(&v, p, sizeof(v));
 return (static\_cast(v) - 32768.0f) / 32768.0f;
 }
 case AUDIO\_S16MSB: {
 int16\_t v = static\_cast((p\[0\] << 8) \| p\[1\]);
 return static\_cast(v) / 32768.0f;
 }
 case AUDIO\_U16MSB: {
 uint16\_t v = static\_cast((p\[0\] << 8) \| p\[1\]);
 return (static\_cast(v) - 32768.0f) / 32768.0f;
 }
 case AUDIO\_S8:
 return static\_cast(\*reinterpret\_cast(p)) / 128.0f;
 case AUDIO\_U8:
 return (static\_cast(\*p) - 128.0f) / 128.0f;
 case AUDIO\_F32LSB: {
 float v;
 std::memcpy(&v, p, sizeof(v));
 return std::clamp(v, -1.0f, 1.0f);
 }
 default:
 return 0.0f;
 }
 };

 for (size\_t frame = 0; frame < frame\_count; ++frame) {
 float sum = 0.0f;
 for (int ch = 0; ch < channels; ++ch) {
 sum += sample\_at(frame \* static\_cast(channels) + static\_cast(ch));
 }
 mono\[frame\] = sum / static\_cast(channels);
 }
 return mono;
}

std::vector resample\_f32\_to\_s16\_pcm(const std::vector& input, int source\_rate, int target\_rate) {
 if (input.empty()) return {};
 double ratio = static\_cast(target\_rate) / static\_cast(source\_rate);
 size\_t out\_count = static\_cast(static\_cast(input.size()) \* ratio);
 if (out\_count == 0) return {};

 std::vector out(out\_count);
 for (size\_t i = 0; i < out\_count; ++i) {
 double src\_pos = static\_cast(i) / ratio;
 size\_t i0 = static\_cast(src\_pos);
 size\_t i1 = std::min(i0 + 1, input.size() - 1);
 double frac = src\_pos - static\_cast(i0);
 double sample = static\_cast(input\[i0\]) \* (1.0 - frac) + static\_cast(input\[i1\]) \* frac;
 sample = std::clamp(sample, -1.0, 1.0);
 out\[i\] = static\_cast(std::lrint(sample \* 32767.0));
 }

 std::vector result(out.size() \* sizeof(int16\_t));
 std::memcpy(result.data(), out.data(), result.size());
 return result;
}

bool record\_audio(std::vector& pcm\_out) {
 if (SDL\_Init(SDL\_INIT\_AUDIO) < 0) {
 std::cerr << "Failed to init SDL audio: " << SDL\_GetError() << "\\n";
 return false;
 }

 SDL\_AudioSpec want;
 SDL\_AudioSpec have;
 SDL\_zero(want);
 want.freq = kRecordSampleRate;
 want.format = AUDIO\_S16LSB;
 want.channels = 1;
 want.samples = static\_cast((kRecordSampleRate \* 100) / 1000);
 want.callback = record\_callback;

 SDL\_AudioDeviceID device = SDL\_OpenAudioDevice(nullptr, 1, &want, &have,
 SDL\_AUDIO\_ALLOW\_FREQUENCY\_CHANGE \|
 SDL\_AUDIO\_ALLOW\_FORMAT\_CHANGE \|
 SDL\_AUDIO\_ALLOW\_CHANNELS\_CHANGE);
 if (device == 0) {
 std::cerr << "Failed to open microphone: " << SDL\_GetError() << "\\n";
 SDL\_QuitSubSystem(SDL\_INIT\_AUDIO);
 return false;
 }

 {
 std::lock\_guard lock(g\_record.mutex);
 g\_record.buffer.clear();
 }
 g\_record.actual\_sample\_rate = have.freq;
 g\_record.actual\_format = have.format;
 g\_record.actual\_channels = have.channels;
 g\_record.recording = true;
 SDL\_PauseAudioDevice(device, 0);

 std::cout << "Recording... press Enter to stop.\\n" << std::flush;
 std::string line;
 std::getline(std::cin, line);

 g\_record.recording = false;
 SDL\_PauseAudioDevice(device, 1);

 {
 std::lock\_guard lock(g\_record.mutex);
 auto mono = decode\_sdl\_audio\_to\_mono\_f32(g\_record.buffer,
 g\_record.actual\_format,
 g\_record.actual\_channels);
 pcm\_out = resample\_f32\_to\_s16\_pcm(mono, g\_record.actual\_sample\_rate, kRecordSampleRate);
 }

 SDL\_CloseAudioDevice(device);
 SDL\_QuitSubSystem(SDL\_INIT\_AUDIO);

 double seconds = static\_cast(pcm\_out.size() / sizeof(int16\_t)) / kRecordSampleRate;
 std::cout << "Recorded " << std::fixed << std::setprecision(1) << seconds << "s of audio.\\n";
 return !pcm\_out.empty();
}
#endif

struct TokenPrinter {
 std::chrono::steady\_clock::time\_point start;
 std::chrono::steady\_clock::time\_point first;
 bool saw\_first = false;
 int count = 0;

 void reset() {
 start = std::chrono::steady\_clock::now();
 saw\_first = false;
 count = 0;
 }

 void on\_token(const char\* text) {
 if (!saw\_first) {
 first = std::chrono::steady\_clock::now();
 saw\_first = true;
 }
 std::cout << (text ? text : "") << std::flush;
 ++count;
 }

 void print\_stats(double ram\_mb) const {
 auto end = std::chrono::steady\_clock::now();
 double total\_s = std::chrono::duration(end - start).count();
 double ttft\_s = saw\_first ? std::chrono::duration(first - start).count() : 0.0;
 double decode\_s = saw\_first ? std::chrono::duration(end - first).count() : total\_s;
 double tps = (count > 1 && decode\_s > 0.0) ? (count - 1) / decode\_s : (total\_s > 0.0 ? count / total\_s : 0.0);
 std::cout << "\\n\[" << count << " tokens \| latency: "\
 << std::fixed << std::setprecision(3) << ttft\_s\
 << "s \| total: " << total\_s\
 << "s \| " << std::setprecision(1) << tps << " tok/s";\
 if (ram\_mb > 0.0) {\
 std::cout << " \| RAM: " << ram\_mb << " MB";\
 }\
 std::cout << "\]\\n";
 }
};

TokenPrinter\* g\_printer = nullptr;

void token\_callback(const char\* text, uint32\_t, void\*) {
 if (g\_printer) {
 g\_printer->on\_token(text);
 }
}

std::string escape\_json(const std::string& s) {
 std::ostringstream out;
 for (unsigned char c : s) {
 switch (c) {
 case '"': out << "\\\\\""; break;
 case '\\\': out << "\\\\\\"; break;
 case '\\b': out << "\\\b"; break;
 case '\\f': out << "\\\f"; break;
 case '\\n': out << "\\\n"; break;
 case '\\r': out << "\\\r"; break;
 case '\\t': out << "\\\t"; break;
 default:
 if (c < 0x20) {
 out << "\\\u" << std::hex << std::setw(4) << std::setfill('0') << static\_cast(c);
 } else {
 out << c;
 }
 }
 }
 return out.str();
}

std::string unescape\_json(const std::string& s) {
 std::string out;
 out.reserve(s.size());
 for (size\_t i = 0; i < s.size(); ++i) {
 if (s\[i\] != '\\\' \|\| i + 1 >= s.size()) {
 out.push\_back(s\[i\]);
 continue;
 }
 char n = s\[++i\];
 switch (n) {
 case '"': out.push\_back('"'); break;
 case '\\\': out.push\_back('\\\'); break;
 case 'b': out.push\_back('\\b'); break;
 case 'f': out.push\_back('\\f'); break;
 case 'n': out.push\_back('\\n'); break;
 case 'r': out.push\_back('\\r'); break;
 case 't': out.push\_back('\\t'); break;
 default: out.push\_back(n); break;
 }
 }
 return out;
}

std::string expand\_tilde(const std::string& path) {
 if (path.size() < 2 \|\| path\[0\] != '~' \|\| path\[1\] != '/') return path;
 const char\* home = std::getenv("HOME");
 return home ? std::string(home) + path.substr(1) : path;
}

bool file\_exists(const std::string& path) {
 std::ifstream f(path);
 return f.good();
}

std::string json\_string\_value(const std::string& json, const std::string& key) {
 std::string needle = "\\"" + key + "\\":\\"";
 size\_t start = json.find(needle);
 if (start == std::string::npos) return {};
 start += needle.size();
 size\_t end = start;
 while ((end = json.find('"', end)) != std::string::npos) {
 size\_t slashes = 0;
 for (size\_t i = end; i > start && json\[i - 1\] == '\\\'; --i) ++slashes;
 if ((slashes % 2) == 0) break;
 ++end;
 }
 if (end == std::string::npos) return {};
 return unescape\_json(json.substr(start, end - start));
}

double json\_number\_value(const std::string& json, const std::string& key) {
 std::string needle = "\\"" + key + "\\":";
 size\_t start = json.find(needle);
 if (start == std::string::npos) return 0.0;
 start += needle.size();
 char\* end = nullptr;
 return std::strtod(json.c\_str() + start, &end);
}

std::string build\_messages(const std::string& system\_prompt,
 const std::vector>& history,
 const std::string& image,
 const std::string& audio,
 bool attach\_media) {
 std::ostringstream msg;
 msg << "\[";\
 bool need\_comma = false;\
 if (!system\_prompt.empty()) {\
 msg << "{\\"role\\":\\"system\\",\\"content\\":\\"" << escape\_json(system\_prompt) << "\\"}";\
 need\_comma = true;\
 }\
 for (size\_t i = 0; i < history.size(); ++i) {\
 if (need\_comma) msg << ",";\
 need\_comma = true;\
 msg << "{\\"role\\":\\"" << history\[i\].first << "\\",\\"content\\":\\""\
 << escape\_json(history\[i\].second) << "\\"";\
 if (attach\_media && i + 1 == history.size() && history\[i\].first == "user") {\
 if (!image.empty()) msg << ",\\"images\\":\[\\"" << escape\_json(image) << "\\"\]";\
 if (!audio.empty()) msg << ",\\"audio\\":\[\\"" << escape\_json(audio) << "\\"\]";\
 }\
 msg << "}";\
 }\
 msg << "\]";
 return msg.str();
}

void print\_usage(const char\* argv0) {
 std::cerr << "Usage: " << argv0
 << "  \[--system \] \[--image \] \[--audio \]"
 << " \[--prompt \] \[--thinking\]\\n";
}

} // namespace

int main(int argc, char\*\* argv) {
 if (argc < 2) {
 print\_usage(argv\[0\]);
 return 1;
 }

 std::string model\_path = argv\[1\];
 std::string system\_prompt;
 std::string current\_image;
 std::string current\_audio;
 std::string initial\_prompt;
 bool thinking = false;

 for (int i = 2; i < argc; ++i) {
 std::string arg = argv\[i\];
 if (arg == "--system" && i + 1 < argc) {
 system\_prompt = argv\[++i\];
 } else if (arg == "--image" && i + 1 < argc) {
 current\_image = expand\_tilde(argv\[++i\]);
 } else if (arg == "--audio" && i + 1 < argc) {
 current\_audio = expand\_tilde(argv\[++i\]);
 } else if (arg == "--prompt" && i + 1 < argc) {
 initial\_prompt = argv\[++i\];
 } else if (arg == "--thinking") {
 thinking = true;
 }
 }

 if (!current\_image.empty() && !file\_exists(current\_image)) {
 std::cerr << "Image not found: " << current\_image << "\\n";
 return 1;
 }
 if (!current\_audio.empty() && !file\_exists(current\_audio)) {
 std::cerr << "Audio file not found: " << current\_audio << "\\n";
 return 1;
 }

 std::cout << "Loading model from " << model\_path << "...\\n";
 cactus\_model\_t model = cactus\_init(model\_path.c\_str(), nullptr, false);
 if (!model) {
 std::cerr << "Failed to initialize model\\n";
 return 1;
 }

 std::cout << "Model loaded.\\n";
 std::cout << "Commands: /image  \[prompt\], /audio  \[prompt\], ";
#ifdef HAVE\_SDL2
 std::cout << "/record \[prompt\], ";
#endif
 std::cout << "/clear, reset, exit\\n\\n";

 std::vector\> history;
 std::vector current\_pcm;
 TokenPrinter printer;
 g\_printer = &printer;
 bool auto\_send = !initial\_prompt.empty() \|\| !current\_audio.empty() \|\| !current\_image.empty();

 while (true) {
 std::string input;
 if (auto\_send) {
 auto\_send = false;
 input = initial\_prompt.empty() ? "Describe the attached input." : initial\_prompt;
 std::cout << "You: " << input << "\\n";
 } else {
 std::cout << "You: " << std::flush;
 if (!std::getline(std::cin, input)) break;
 }

 while (!input.empty() && (input.back() == ' ' \|\| input.back() == '\\t')) input.pop\_back();
 if (input.empty()) continue;
 if (input == "exit" \|\| input == "quit") break;
 if (input == "reset") {
 history.clear();
 current\_image.clear();
 current\_audio.clear();
 current\_pcm.clear();
 cactus\_reset(model);
 std::cout << "Conversation reset.\\n";
 continue;
 }
 if (input == "/clear") {
 current\_image.clear();
 current\_audio.clear();
 current\_pcm.clear();
 std::cout << "Attachments cleared.\\n";
 continue;
 }

 auto parse\_attachment = \[&\](const std::string& prefix, std::string& target) -> bool {
 if (input.rfind(prefix, 0) != 0) return false;
 std::string rest = input.substr(prefix.size());
 size\_t split = rest.find(' ');
 std::string path = expand\_tilde(split == std::string::npos ? rest : rest.substr(0, split));
 if (!file\_exists(path)) {
 std::cerr << "File not found: " << path << "\\n";
 input.clear();
 return true;
 }
 target = path;
 input = split == std::string::npos ? "" : rest.substr(split + 1);
 return true;
 };

 if (parse\_attachment("/image ", current\_image) && input.empty()) {
 std::cout << "Image attached: " << current\_image << "\\n";
 continue;
 }
 if (parse\_attachment("/audio ", current\_audio) && input.empty()) {
 std::cout << "Audio attached: " << current\_audio << "\\n";
 continue;
 }

 if (input == "/record" \|\| input.rfind("/record ", 0) == 0) {
#ifdef HAVE\_SDL2
 std::string record\_prompt;
 if (input.size() > 8) {
 record\_prompt = input.substr(8);
 while (!record\_prompt.empty() && (record\_prompt.front() == ' ' \|\| record\_prompt.front() == '\\t')) {
 record\_prompt.erase(record\_prompt.begin());
 }
 }
 current\_pcm.clear();
 current\_audio.clear();
 if (!record\_audio(current\_pcm)) {
 std::cerr << "Recording failed.\\n";
 continue;
 }
 input = record\_prompt.empty() ? "Transcribe or respond to this audio." : record\_prompt;
#else
 std::cerr << "Recording requires SDL2, but this chat binary was built without SDL2.\\n";
 continue;
#endif
 }
 if (input.empty()) continue;

 bool attach\_media = !current\_image.empty() \|\| !current\_audio.empty() \|\| !current\_pcm.empty();
 if (attach\_media) {
 cactus\_reset(model);
 }
 history.push\_back({"user", input});
 std::string messages = build\_messages(system\_prompt, history, current\_image, current\_audio, attach\_media);
 std::string options = "{\\"temperature\\":0.7,\\"top\_p\\":0.95,\\"top\_k\\":40,\\"max\_tokens\\":"
 \+ std::to\_string(kMaxTokens)
 \+ ",\\"enable\_thinking\_if\_supported\\":" + (thinking ? "true" : "false")
 \+ ",\\"auto\_handoff\\":false,\\"confidence\_threshold\\":0.0"
 \+ ",\\"stop\_sequences\\":\[\\"<\|im\_end\|>\\",\\"\\"\]}";

 if (!current\_image.empty()) std::cout << "\[image: " << current\_image << "\]\\n";
 if (!current\_audio.empty()) std::cout << "\[audio: " << current\_audio << "\]\\n";
 if (!current\_pcm.empty()) {
 double seconds = static\_cast(current\_pcm.size() / sizeof(int16\_t)) / 16000.0;
 std::cout << "\[recorded audio: " << std::fixed << std::setprecision(1) << seconds << "s\]\\n";
 }
 std::cout << "Assistant: " << std::flush;

 std::vector response(kResponseBufferSize, 0);
 printer.reset();
 int rc = cactus\_complete(model,
 messages.c\_str(),
 response.data(),
 response.size(),
 options.c\_str(),
 nullptr,
 token\_callback,
 nullptr,
 current\_pcm.empty() ? nullptr : current\_pcm.data(),
 current\_pcm.size());

 std::string response\_json(response.data());
 double ram\_mb = json\_number\_value(response\_json, "ram\_usage\_mb");
 printer.print\_stats(ram\_mb);
 std::cout << "\\n";

 if (rc < 0) {
 std::cerr << "Error: " << response.data() << "\\n";
 history.pop\_back();
 continue;
 }

 std::string assistant = json\_string\_value(response\_json, "response");
 history.push\_back({"assistant", assistant});
 current\_image.clear();
 current\_audio.clear();
 current\_pcm.clear();
 }

 cactus\_destroy(model);
 std::cout << "Goodbye.\\n";
 return 0;
}