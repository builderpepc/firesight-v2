#include "test\_utils.h"
#include
#include
#include
#include
#include
#include

#if \_\_has\_include()
#include
#define CACTUS\_ENGINE\_TEST\_HAS\_CURL 1
#else
#define CACTUS\_ENGINE\_TEST\_HAS\_CURL 0
#endif

using namespace EngineTestUtils;

static const char\* g\_model\_path = std::getenv("CACTUS\_TEST\_MODEL");

static const char\* g\_options = R"({
 "max\_tokens": 256,
 "stop\_sequences": \["<\|im\_end\|>", ""\],
 "telemetry\_enabled": false
 })";

template
bool run\_test(const char\* title, const char\* messages, TestFunc test\_logic,
 const char\* tools = nullptr, int stop\_at = -1) {
 return EngineTestUtils::run\_test(title, g\_model\_path, messages, g\_options, test\_logic, tools, stop\_at);
}

bool test\_streaming() {
 std::cout << "\\n╔══════════════════════════════════════════╗\\n"
 << "║" << std::setw(42) << std::left << " STREAMING & FOLLOW-UP TEST" << "║\\n"
 << "╚══════════════════════════════════════════╝\\n";

 cactus\_model\_t model = cactus\_init(g\_model\_path, nullptr, false);
 if (!model) {
 std::cerr << "\[✗\] Failed to initialize model\\n";
 return false;
 }

 const char\* messages1 = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "My name is Henry Ndubuaku, how are you?"}\
 \])";

 StreamingData data1;
 data1.model = model;
 char response1\[4096\];

 std::cout << "\\n\[Turn 1\]\\n";
 std::cout << "User: My name is Henry Ndubuaku, how are you?\\n";
 std::cout << "Assistant: ";

 int result1 = cactus\_complete(model, messages1, response1, sizeof(response1),
 g\_options, nullptr, stream\_callback, &data1, nullptr, 0);

 std::cout << "\\n\\n\[Results - Turn 1\]\\n";
 Metrics metrics1;
 metrics1.parse(response1);
 metrics1.print\_json();

 bool success1 = result1 > 0 && data1.token\_count > 0;

 if (!success1) {
 std::cout << "└─ Status: FAILED ✗\\n";
 cactus\_destroy(model);
 return false;
 }

 std::string assistant\_response;
 for(const auto& token : data1.tokens) {
 assistant\_response += token;
 }

 std::string messages2\_str = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "My name is Henry Ndubuaku, how are you?"},\
 {"role": "assistant", "content": ")" + escape\_json(assistant\_response) + R"("},\
 {"role": "user", "content": "What is my name?"}\
 \])";

 StreamingData data2;
 data2.model = model;
 char response2\[4096\];

 std::cout << "\\n\[Turn 2\]\\n";
 std::cout << "User: What is my name?\\n";
 std::cout << "Assistant: ";

 int result2 = cactus\_complete(model, messages2\_str.c\_str(), response2, sizeof(response2),
 g\_options, nullptr, stream\_callback, &data2, nullptr, 0);

 std::cout << "\\n\\n\[Results - Turn 2\]\\n";
 Metrics metrics2;
 metrics2.parse(response2);
 metrics2.print\_json();

 bool success2 = result2 > 0 && data2.token\_count > 0;

 cactus\_destroy(model);
 return success1 && success2;
}

bool test\_prefill\_idempotent\_reuse() {
 std::cout << "\\n╔══════════════════════════════════════════╗\\n"
 << "║" << std::setw(42) << std::left << " PREFILL IDEMPOTENT REUSE TEST" << "║\\n"
 << "╚══════════════════════════════════════════╝\\n";

 cactus\_model\_t model = cactus\_init(g\_model\_path, nullptr, false);
 if (!model) {
 std::cerr << "\[✗\] Failed to initialize model\\n";
 return false;
 }

 const char\* messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "Write one short sentence about brainrot."}\
 \])";

 const char\* tools = R"(\[{\
 "type": "function",\
 "function": {\
 "name": "summarize\_topic",\
 "description": "Summarize a topic in one short sentence",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "topic": {"type": "string", "description": "Topic to summarize"}\
 },\
 "required": \["topic"\]\
 }\
 }\
 }\])";

 char prefill\_response1\[2048\] = {0};
 int prefill\_result1 = cactus\_prefill(model, messages, prefill\_response1, sizeof(prefill\_response1), nullptr, tools, nullptr, 0);

 PrefillMetrics prefill\_metrics1;
 prefill\_metrics1.parse(prefill\_response1);

 char prefill\_response2\[2048\] = {0};
 int prefill\_result2 = cactus\_prefill(model, messages, prefill\_response2, sizeof(prefill\_response2), nullptr, tools, nullptr, 0);

 PrefillMetrics prefill\_metrics2;
 prefill\_metrics2.parse(prefill\_response2);

 std::cout << "\\n\\n\[Results\]\\n";
 std::cout << "├─ Prefill#1 benchmark: ";
 prefill\_metrics1.print\_line();
 std::cout << "\\n"
 << "├─ Prefill#2 benchmark: ";
 prefill\_metrics2.print\_line();
 std::cout << "\\n";

 bool prefill\_success = prefill\_result1 > 0 && prefill\_result2 > 0
 && prefill\_metrics1.success && prefill\_metrics2.success;
 bool skipped\_recompute = prefill\_metrics2.prefill\_tokens == 0;

 std::cout << "├─ Prefill calls success: " << (prefill\_success ? "YES" : "NO") << "\\n"
 << "└─ Second prefill skipped recompute: " << (skipped\_recompute ? "YES" : "NO") << std::endl;

 cactus\_destroy(model);
 return prefill\_success && skipped\_recompute;
}

bool test\_prefill\_prefix\_extension\_reuse() {
 std::cout << "\\n╔══════════════════════════════════════════╗\\n"
 << "║" << std::setw(42) << std::left << " PREFILL PREFIX EXTENSION TEST" << "║\\n"
 << "╚══════════════════════════════════════════╝\\n";

 cactus\_model\_t model = cactus\_init(g\_model\_path, nullptr, false);
 if (!model) {
 std::cerr << "\[✗\] Failed to initialize model\\n";
 return false;
 }

 const char\* messages\_base = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "Write one short sentence about brainrot."}\
 \])";

 const char\* messages\_extended = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "Write one short sentence about brainrot."},\
 {"role": "assistant", "content": "Brainrot is internet slang for obsessive, meme-heavy online fixation."},\
 {"role": "user", "content": "Now rewrite that in six words."}\
 \])";

 const char\* tools = R"(\[{\
 "type": "function",\
 "function": {\
 "name": "summarize\_topic",\
 "description": "Summarize a topic in one short sentence",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "topic": {"type": "string", "description": "Topic to summarize"}\
 },\
 "required": \["topic"\]\
 }\
 }\
 }\])";

 char prefill\_response1\[2048\] = {0};
 int prefill\_result1 = cactus\_prefill(model, messages\_base, prefill\_response1, sizeof(prefill\_response1), nullptr, tools, nullptr, 0);
 PrefillMetrics prefill\_metrics1;
 prefill\_metrics1.parse(prefill\_response1);

 char prefill\_response2\[2048\] = {0};
 int prefill\_result2 = cactus\_prefill(model, messages\_extended, prefill\_response2, sizeof(prefill\_response2), nullptr, tools, nullptr, 0);
 PrefillMetrics prefill\_metrics2;
 prefill\_metrics2.parse(prefill\_response2);

 cactus\_reset(model);

 char prefill\_response3\[2048\] = {0};
 int prefill\_result3 = cactus\_prefill(model, messages\_extended, prefill\_response3, sizeof(prefill\_response3), nullptr, tools, nullptr, 0);
 PrefillMetrics prefill\_metrics3;
 prefill\_metrics3.parse(prefill\_response3);

 std::cout << "\\n\\n\[Results\]\\n";
 std::cout << "├─ Prefill#1 (base): ";
 prefill\_metrics1.print\_line();
 std::cout << "\\n"
 << "├─ Prefill#2 (extended, warm): ";
 prefill\_metrics2.print\_line();
 std::cout << "\\n"
 << "├─ Prefill#3 (extended, cold): ";
 prefill\_metrics3.print\_line();
 std::cout << "\\n";

 bool prefill\_success = prefill\_result1 > 0 && prefill\_result2 > 0 && prefill\_result3 > 0
 && prefill\_metrics1.success && prefill\_metrics2.success && prefill\_metrics3.success;
 bool second\_call\_prefilled = prefill\_metrics2.prefill\_tokens > 0;
 bool warm\_reused\_prefix = prefill\_metrics2.prefill\_tokens < prefill\_metrics3.prefill\_tokens;

 std::cout << "├─ Prefill calls success: " << (prefill\_success ? "YES" : "NO") << "\\n"
 << "├─ Warm extension prefilled tokens: " << (second\_call\_prefilled ? "YES" : "NO") << "\\n"
 << "└─ Warm extension < cold extension: " << (warm\_reused\_prefix ? "YES" : "NO") << std::endl;

 cactus\_destroy(model);
 return prefill\_success && second\_call\_prefilled && warm\_reused\_prefix;
}

bool test\_prefill\_invalidated\_on\_message\_change() {
 std::cout << "\\n╔══════════════════════════════════════════╗\\n"
 << "║" << std::setw(42) << std::left << " PREFILL INVALIDATION (LLM) TEST" << "║\\n"
 << "╚══════════════════════════════════════════╝\\n";

 cactus\_model\_t model = cactus\_init(g\_model\_path, nullptr, false);
 if (!model) {
 std::cerr << "\[✗\] Failed to initialize model\\n";
 return false;
 }

 const char\* prefill\_messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "Summarize the phrase 'brainrot' in one sentence."}\
 \])";

 const char\* complete\_messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "Give one sentence about the power of the 'brainrot'."}\
 \])";

 const char\* options = R"({
 "max\_tokens": 128,
 "stop\_sequences": \["<\|im\_end\|>", ""\],
 "confidence\_threshold": 0.0,
 "telemetry\_enabled": false
 })";

 char prefill\_response\[2048\] = {0};
 int prefill\_result = cactus\_prefill(model, prefill\_messages, prefill\_response, sizeof(prefill\_response), nullptr, nullptr, nullptr, 0);
 PrefillMetrics prefill\_metrics;
 prefill\_metrics.parse(prefill\_response);

 char complete\_response\_warm\[4096\] = {0};
 int complete\_result\_warm = cactus\_complete(model, complete\_messages, complete\_response\_warm, sizeof(complete\_response\_warm),
 options, nullptr, nullptr, nullptr, nullptr, 0);
 Metrics warm\_metrics;
 warm\_metrics.parse(complete\_response\_warm);

 cactus\_reset(model);

 char complete\_response\_cold\[4096\] = {0};
 int complete\_result\_cold = cactus\_complete(model, complete\_messages, complete\_response\_cold, sizeof(complete\_response\_cold),
 options, nullptr, nullptr, nullptr, nullptr, 0);
 Metrics cold\_metrics;
 cold\_metrics.parse(complete\_response\_cold);

 std::cout << "\\n\\n\[Results\]\\n";
 std::cout << "├─ Prefill success: " << ((prefill\_result > 0 && prefill\_metrics.success) ? "YES" : "NO") << "\\n"
 << "├─ Complete(warm mismatched) prefill\_tokens: " << warm\_metrics.prefill\_tokens << "\\n"
 << "├─ Complete(cold) prefill\_tokens: " << cold\_metrics.prefill\_tokens << "\\n";

 bool all\_success = prefill\_result > 0 && prefill\_metrics.success
 && complete\_result\_warm > 0 && warm\_metrics.success
 && complete\_result\_cold > 0 && cold\_metrics.success;
 bool invalidated = warm\_metrics.prefill\_tokens == cold\_metrics.prefill\_tokens;

 std::cout << "├─ Calls successful: " << (all\_success ? "YES" : "NO") << "\\n"
 << "└─ Mismatch invalidated cache: " << (invalidated ? "YES" : "NO") << std::endl;

 cactus\_destroy(model);
 return all\_success && invalidated;
}

bool test\_prefill() {
 std::cout << "\\n╔══════════════════════════════════════════╗\\n"
 << "║" << std::setw(42) << std::left << " PREFILL API TEST" << "║\\n"
 << "╚══════════════════════════════════════════╝\\n";

 cactus\_model\_t model = cactus\_init(g\_model\_path, nullptr, false);
 if (!model) {
 std::cerr << "\[✗\] Failed to initialize model\\n";
 return false;
 }

 const char\* prefill\_messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "Explain what brainrot means in one short sentence."},\
 {"role": "assistant", "content": "Brainrot is internet slang for obsessive, meme-heavy online fixation."}\
 \])";

 const char\* complete\_messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant. Be concise."},\
 {"role": "user", "content": "Explain what brainrot means in one short sentence."},\
 {"role": "assistant", "content": "Brainrot is internet slang for obsessive, meme-heavy online fixation."},\
 {"role": "user", "content": "Now rewrite that in six words."}\
 \])";

 const char\* options = R"({
 "max\_tokens": 128,
 "stop\_sequences": \["<\|im\_end\|>", ""\],
 "confidence\_threshold": 0.0,
 "telemetry\_enabled": false
 })";

 char prefill\_response\[2048\] = {0};
 int prefill\_result = cactus\_prefill(model, prefill\_messages, prefill\_response, sizeof(prefill\_response), nullptr, nullptr, nullptr, 0);
 PrefillMetrics prefill\_metrics;
 prefill\_metrics.parse(prefill\_response);

 char complete\_response\_warm\[4096\] = {0};
 int complete\_result\_warm = cactus\_complete(model, complete\_messages, complete\_response\_warm, sizeof(complete\_response\_warm),
 options, nullptr, nullptr, nullptr, nullptr, 0);
 Metrics warm\_metrics;
 warm\_metrics.parse(complete\_response\_warm);

 cactus\_reset(model);

 char complete\_response\_cold\[4096\] = {0};
 int complete\_result\_cold = cactus\_complete(model, complete\_messages, complete\_response\_cold, sizeof(complete\_response\_cold),
 options, nullptr, nullptr, nullptr, nullptr, 0);
 Metrics cold\_metrics;
 cold\_metrics.parse(complete\_response\_cold);

 std::cout << "\\n\\n\[Results\]\\n";
 std::cout << "├─ Prefill success: " << ((prefill\_result > 0 && prefill\_metrics.success) ? "YES" : "NO") << "\\n"
 << "├─ Prefill metrics: ";
 prefill\_metrics.print\_line();
 std::cout << "\\n";
 std::cout << "├─ Complete warm metrics:\\n";
 warm\_metrics.print\_json();
 std::cout << "├─ Complete cold metrics:\\n";
 cold\_metrics.print\_json();

 bool all\_success = prefill\_result > 0 && prefill\_metrics.success
 && complete\_result\_warm > 0 && warm\_metrics.success
 && complete\_result\_cold > 0 && cold\_metrics.success;
 bool warm\_prefilled\_less = warm\_metrics.prefill\_tokens < cold\_metrics.prefill\_tokens;

 std::cout << "├─ Calls successful: " << (all\_success ? "YES" : "NO") << "\\n"
 << "└─ Warm prefilled less than cold: " << (warm\_prefilled\_less ? "YES" : "NO") << std::endl;

 cactus\_destroy(model);
 return all\_success && warm\_prefilled\_less;
}

bool test\_tool\_call() {
 const char\* messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant that can use tools."},\
 {"role": "user", "content": "What's the weather in San Francisco?"}\
 \])";

 const char\* tools = R"(\[{\
 "type": "function",\
 "function": {\
 "name": "get\_weather",\
 "description": "Get weather for a location",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "location": {"type": "string", "description": "City, State, Country"}\
 },\
 "required": \["location"\]\
 }\
 }\
 }\])";

 const char\* options\_with\_force\_tools = R"({
 "max\_tokens": 256,
 "stop\_sequences": \["<\|im\_end\|>", ""\],
 "force\_tools": true
 })";

 return EngineTestUtils::run\_test("TOOL CALL TEST", g\_model\_path, messages, options\_with\_force\_tools,
 \[\](int result, const StreamingData&, const std::string& response, const Metrics& m) {
 bool has\_function = response.find("\\"function\_calls\\":\[") != std::string::npos;\
 bool has\_tool = has\_function && response.find("get\_weather") != std::string::npos;\
 std::cout << "├─ Function call: " << (has\_function ? "YES" : "NO") << "\\n"\
 << "├─ Correct tool: " << (has\_tool ? "YES" : "NO") << "\\n";\
 m.print\_json();\
 return result > 0 && has\_function && has\_tool;\
 }, tools, -1, "What's the weather in San Francisco?");\
}\
\
bool test\_multiple\_tool\_call\_invocations() {\
 const char\* messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant that can use tools."},\
 {"role": "user", "content": "Send a message to Bob and get the weather for San Francisco."}\
 \])";\
\
 const char\* tools = R"(\[{\
 "type": "function",\
 "function": {\
 "name": "get\_weather",\
 "description": "Get weather for a location",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "location": {"type": "string", "description": "City, State, Country"}\
 },\
 "required": \["location"\]\
 }\
 }\
 }, {\
 "type": "function",\
 "function": {\
 "name": "send\_message",\
 "description": "Send a message to a contact",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "recipient": {"type": "string", "description": "Name of the person to send the message to"},\
 "message": {"type": "string", "description": "The message content to send"}\
 },\
 "required": \["recipient", "message"\]\
 }\
 }\
 }\])";\
\
 const char\* options\_with\_force\_tools = R"({\
 "max\_tokens": 256,\
 "stop\_sequences": \["<\|im\_end\|>", ""\],\
 "force\_tools": true\
 })";\
\
 return EngineTestUtils::run\_test("MULTIPLE TOOLS TEST", g\_model\_path, messages, options\_with\_force\_tools,\
 \[\](int result, const StreamingData&, const std::string& response, const Metrics& m) {\
 bool has\_function = response.find("\\"function\_calls\\":\[") != std::string::npos;\
 bool has\_weather\_tool = has\_function\
 && (response.find("\\"name\\":\\"get\_weather\\"") != std::string::npos\
 \|\| response.find("\\"name\\": \\"get\_weather\\"") != std::string::npos);\
 bool has\_message\_tool = has\_function\
 && (response.find("\\"name\\":\\"send\_message\\"") != std::string::npos\
 \|\| response.find("\\"name\\": \\"send\_message\\"") != std::string::npos);\
 std::cout << "├─ Function call: " << (has\_function ? "YES" : "NO") << "\\n"\
 << "├─ Correct tool: " << (has\_weather\_tool && has\_message\_tool ? "YES" : "NO") << "\\n";\
 m.print\_json();\
 return result > 0 && has\_function && has\_weather\_tool && has\_message\_tool;\
 }, tools, -1, "Send a message to Bob and get the weather for San Francisco.");\
}\
\
bool test\_tool\_call\_with\_three\_tools() {\
 const char\* messages = R"(\[\
 {"role": "system", "content": "You are a helpful assistant that can use tools."},\
 {"role": "user", "content": "Send a message to John saying hello."}\
 \])";\
\
 const char\* tools = R"(\[{\
 "type": "function",\
 "function": {\
 "name": "get\_weather",\
 "description": "Get weather for a location",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "location": {"type": "string", "description": "City, State, Country"}\
 },\
 "required": \["location"\]\
 }\
 }\
 }, {\
 "type": "function",\
 "function": {\
 "name": "set\_alarm",\
 "description": "Set an alarm for a given time",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "hour": {"type": "integer", "description": "Hour to set the alarm for"},\
 "minute": {"type": "integer", "description": "Minute to set the alarm for"}\
 },\
 "required": \["hour", "minute"\]\
 }\
 }\
 }, {\
 "type": "function",\
 "function": {\
 "name": "send\_message",\
 "description": "Send a message to a contact",\
 "parameters": {\
 "type": "object",\
 "properties": {\
 "recipient": {"type": "string", "description": "Name of the person to send the message to"},\
 "message": {"type": "string", "description": "The message content to send"}\
 },\
 "required": \["recipient", "message"\]\
 }\
 }\
 }\])";\
\
 const char\* options\_with\_force\_tools = R"({\
 "max\_tokens": 256,\
 "stop\_sequences": \["<\|im\_end\|>", ""\],\
 "force\_tools": true\
 })";\
\
 return EngineTestUtils::run\_test("TRIPLE TOOLS TEST", g\_model\_path, messages, options\_with\_force\_tools,\
 \[\](int result, const StreamingData&, const std::string& response, const Metrics& m) {\
 bool has\_function = response.find("\\"function\_calls\\":\[") != std::string::npos;\
 bool has\_tool = has\_function && response.find("send\_message") != std::string::npos;\
 std::cout << "├─ Function call: " << (has\_function ? "YES" : "NO") << "\\n"\
 << "├─ Correct tool: " << (has\_tool ? "YES" : "NO") << "\\n";\
 m.print\_json();\
 return result > 0 && has\_function && has\_tool;\
 }, tools, -1, "Send a message to John saying hello.");\
}\
\
bool test\_1k\_context() {\
 std::string msg = "\[{\\"role\\": \\"system\\", \\"content\\": \\"/no\_think You are helpful. ";\
 for (int i = 0; i < 50; i++) {\
 msg += "Context " + std::to\_string(i) + ": Background knowledge. ";\
 }\
 msg += "\\"}, {\\"role\\": \\"user\\", \\"content\\": \\"";\
 for (int i = 0; i < 50; i++) {\
 msg += "Data " + std::to\_string(i) + " = " + std::to\_string(i \* 3.14159) + ". ";\
 }\
 msg += "Explain the data.\\"}\]";\
\
 return run\_test("1K CONTEXT TEST", msg.c\_str(),\
 \[\](int result, const StreamingData&, const std::string&, const Metrics& m) {\
 m.print\_json();\
 return result > 0;\
 }, nullptr, 100);\
}\
\
int main() {\
 TestUtils::TestRunner runner("LLM Tests");\
 const char\* only = std::getenv("CACTUS\_TEST\_ONLY");\
 auto should\_run = \[&\](const char\* name) {\
 return only == nullptr \|\| std::string(only) == name;\
 };\
 if (should\_run("1k\_context")) runner.run\_test("1k\_context", test\_1k\_context());\
 if (should\_run("streaming")) runner.run\_test("streaming", test\_streaming());\
 if (should\_run("prefill")) runner.run\_test("prefill", test\_prefill());\
 if (should\_run("prefill\_idempotent\_reuse")) runner.run\_test("prefill\_idempotent\_reuse", test\_prefill\_idempotent\_reuse());\
 if (should\_run("prefill\_prefix\_extension\_reuse")) runner.run\_test("prefill\_prefix\_extension\_reuse", test\_prefill\_prefix\_extension\_reuse());\
 if (should\_run("prefill\_invalidated\_on\_message\_change")) runner.run\_test("prefill\_invalidated\_on\_message\_change", test\_prefill\_invalidated\_on\_message\_change());\
 if (should\_run("tool\_calls")) runner.run\_test("tool\_calls", test\_tool\_call());\
 if (should\_run("tool\_multiple\_tool\_call\_invocations")) runner.run\_test("tool\_multiple\_tool\_call\_invocations", test\_multiple\_tool\_call\_invocations());\
 if (should\_run("tool\_calls\_with\_three\_tools")) runner.run\_test("tool\_calls\_with\_three\_tools", test\_tool\_call\_with\_three\_tools());\
 runner.print\_summary();\
 return runner.all\_passed() ? 0 : 1;\
}