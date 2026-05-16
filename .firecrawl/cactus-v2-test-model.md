#include "test\_utils.h"
#include
#include

namespace fs = std::filesystem;

static std::string make\_temp\_dir(const std::string& suffix) {
 std::string dir = fs::temp\_directory\_path().string() + "/cactus\_test\_" + suffix;
 fs::create\_directories(dir);
 return dir;
}

static void write\_file(const std::string& path, const std::string& content) {
 std::ofstream(path, std::ios::binary) << content;
}

static bool expect\_init\_fails(const std::string& path) {
 cactus\_model\_t model = cactus\_init(path.c\_str(), nullptr, false);
 if (model) { cactus\_destroy(model); return false; }
 return true;
}

static const char\* MINIMAL\_CONFIG = R"({"model\_type":"qwen","model\_variant":"default","precision":"INT8","num\_layers":2,"hidden\_dim":64,"ffn\_intermediate\_dim":128,"attention\_heads":2,"attention\_kv\_heads":2,"attention\_head\_dim":32,"vocab\_size":100,"context\_length":512})";

static bool test\_missing\_directory() {
 return expect\_init\_fails("/nonexistent/path/to/model");
}

static bool test\_missing\_config() {
 std::string dir = make\_temp\_dir("missing\_config");
 write\_file(dir + "/dummy.bin", "placeholder");
 bool ok = expect\_init\_fails(dir);
 fs::remove\_all(dir);
 return ok;
}

static bool test\_corrupt\_weights() {
 std::string dir = make\_temp\_dir("corrupt\_weights");
 write\_file(dir + "/config.txt", MINIMAL\_CONFIG);
 write\_file(dir + "/vocab.txt", "hello\\nworld\\n");
 write\_file(dir + "/weights.bin", std::string("\\xDE\\xAD\\xBE\\xEF", 4) + std::string(124, '\\xDE'));
 bool ok = expect\_init\_fails(dir);
 fs::remove\_all(dir);
 return ok;
}

static bool test\_empty\_weight\_file() {
 std::string dir = make\_temp\_dir("empty\_weights");
 write\_file(dir + "/config.txt", MINIMAL\_CONFIG);
 write\_file(dir + "/vocab.txt", "hello\\nworld\\n");
 write\_file(dir + "/weights.bin", "");
 bool ok = expect\_init\_fails(dir);
 fs::remove\_all(dir);
 return ok;
}

static bool test\_missing\_vocab() {
 std::string dir = make\_temp\_dir("missing\_vocab");
 write\_file(dir + "/config.txt", MINIMAL\_CONFIG);
 bool ok = expect\_init\_fails(dir);
 fs::remove\_all(dir);
 return ok;
}

int main() {
 TestUtils::TestRunner runner("Model Loading Failure Tests");
 runner.run\_test("missing\_directory", test\_missing\_directory());
 runner.run\_test("missing\_config", test\_missing\_config());
 runner.run\_test("corrupt\_weights", test\_corrupt\_weights());
 runner.run\_test("empty\_weight\_file", test\_empty\_weight\_file());
 runner.run\_test("missing\_vocab", test\_missing\_vocab());
 runner.print\_summary();
 return runner.all\_passed() ? 0 : 1;
}