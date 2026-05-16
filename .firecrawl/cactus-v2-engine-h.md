#ifndef CACTUS\_FFI\_H
#define CACTUS\_FFI\_H

#include
#include
#include

#if \_\_GNUC\_\_ >= 4
 #define CACTUS\_FFI\_EXPORT \_\_attribute\_\_((visibility("default")))
 #define CACTUS\_FFI\_LOCAL \_\_attribute\_\_((visibility("hidden")))
#else
 #define CACTUS\_FFI\_EXPORT
 #define CACTUS\_FFI\_LOCAL
#endif

#ifdef \_\_cplusplus
extern "C" {
#endif

typedef void\* cactus\_model\_t;
typedef void\* cactus\_index\_t;
typedef void (\*cactus\_token\_callback)(const char\* token, uint32\_t token\_id, void\* user\_data);

CACTUS\_FFI\_EXPORT cactus\_model\_t cactus\_init(
 const char\* model\_path,
 const char\* corpus\_dir, // optional: NULL if no RAG corpus
 bool cache\_index // false = always rebuild index, true = load cached if available
);

CACTUS\_FFI\_EXPORT void cactus\_destroy(cactus\_model\_t model);
CACTUS\_FFI\_EXPORT void cactus\_reset(cactus\_model\_t model);
CACTUS\_FFI\_EXPORT void cactus\_stop(cactus\_model\_t model);

CACTUS\_FFI\_EXPORT int cactus\_complete(
 cactus\_model\_t model,
 const char\* messages\_json,
 char\* response\_buffer,
 size\_t buffer\_size,
 const char\* options\_json, // optional
 const char\* tools\_json, // optional
 cactus\_token\_callback callback, // optional
 void\* user\_data, // optional
 const uint8\_t\* pcm\_buffer, // optional: NULL when not used
 size\_t pcm\_buffer\_size // optional: 0 when not used
);

CACTUS\_FFI\_EXPORT int cactus\_prefill(
 cactus\_model\_t model,
 const char\* messages\_json,
 char\* response\_buffer,
 size\_t buffer\_size,
 const char\* options\_json, // optional
 const char\* tools\_json, // optional
 const uint8\_t\* pcm\_buffer, // optional: NULL when not used
 size\_t pcm\_buffer\_size // optional: 0 when not used
);

CACTUS\_FFI\_EXPORT int cactus\_tokenize(
 cactus\_model\_t model,
 const char\* text,
 uint32\_t\* token\_buffer,
 size\_t token\_buffer\_len,
 size\_t\* out\_token\_len
);

CACTUS\_FFI\_EXPORT int cactus\_score\_window(
 cactus\_model\_t model,
 const uint32\_t\* tokens,
 size\_t token\_len,
 size\_t start,
 size\_t end,
 size\_t context,
 char\* response\_buffer,
 size\_t buffer\_size
);

CACTUS\_FFI\_EXPORT int cactus\_transcribe(
 cactus\_model\_t model,
 const char\* audio\_file\_path, // NULL if using pcm\_buffer
 const char\* prompt,
 char\* response\_buffer,
 size\_t buffer\_size,
 const char\* options\_json, // optional
 cactus\_token\_callback callback, // optional
 void\* user\_data, // optional
 const uint8\_t\* pcm\_buffer, // NULL if using audio\_file\_path
 size\_t pcm\_buffer\_size
);

CACTUS\_FFI\_EXPORT int cactus\_embed(
 cactus\_model\_t model,
 const char\* text,
 float\* embeddings\_buffer,
 size\_t buffer\_size,
 size\_t\* embedding\_dim,
 bool normalize
);

CACTUS\_FFI\_EXPORT int cactus\_image\_embed(
 cactus\_model\_t model,
 const char\* image\_path,
 float\* embeddings\_buffer,
 size\_t buffer\_size,
 size\_t\* embedding\_dim
);

CACTUS\_FFI\_EXPORT int cactus\_audio\_embed(
 cactus\_model\_t model,
 const char\* audio\_path,
 float\* embeddings\_buffer,
 size\_t buffer\_size,
 size\_t\* embedding\_dim
);

CACTUS\_FFI\_EXPORT int cactus\_vad(
 cactus\_model\_t model,
 const char\* audio\_file\_path,
 char\* response\_buffer,
 size\_t buffer\_size,
 const char\* options\_json,
 const uint8\_t\* pcm\_buffer,
 size\_t pcm\_buffer\_size
);

CACTUS\_FFI\_EXPORT int cactus\_diarize(
 cactus\_model\_t model,
 const char\* audio\_file\_path,
 char\* response\_buffer,
 size\_t buffer\_size,
 const char\* options\_json,
 const uint8\_t\* pcm\_buffer,
 size\_t pcm\_buffer\_size
);

CACTUS\_FFI\_EXPORT int cactus\_embed\_speaker(
 cactus\_model\_t model,
 const char\* audio\_file\_path,
 char\* response\_buffer,
 size\_t buffer\_size,
 const char\* options\_json,
 const uint8\_t\* pcm\_buffer,
 size\_t pcm\_buffer\_size,
 const float\* mask\_weights,
 size\_t mask\_num\_frames
);

CACTUS\_FFI\_EXPORT int cactus\_rag\_query(
 cactus\_model\_t model,
 const char\* query,
 char\* response\_buffer,
 size\_t buffer\_size,
 size\_t top\_k
);

CACTUS\_FFI\_EXPORT cactus\_index\_t cactus\_index\_init(
 const char\* index\_dir,
 size\_t embedding\_dim
);

CACTUS\_FFI\_EXPORT int cactus\_index\_add(
 cactus\_index\_t index,
 const int\* ids,
 const char\*\* documents,
 const char\*\* metadatas, // optional: can be NULL
 const float\*\* embeddings,
 size\_t count,
 size\_t embedding\_dim
);

CACTUS\_FFI\_EXPORT int cactus\_index\_delete(
 cactus\_index\_t index,
 const int\* ids,
 size\_t ids\_count
);

CACTUS\_FFI\_EXPORT int cactus\_index\_get(
 cactus\_index\_t index,
 const int\* ids,
 size\_t ids\_count,
 char\*\* document\_buffers,
 size\_t\* document\_buffer\_sizes,
 char\*\* metadata\_buffers,
 size\_t\* metadata\_buffer\_sizes,
 float\*\* embedding\_buffers,
 size\_t\* embedding\_buffer\_sizes
);

CACTUS\_FFI\_EXPORT int cactus\_index\_query(
 cactus\_index\_t index,
 const float\*\* embeddings,
 size\_t embeddings\_count,
 size\_t embedding\_dim,
 const char\* options\_json, // optional
 int\*\* id\_buffers,
 size\_t\* id\_buffer\_sizes,
 float\*\* score\_buffers,
 size\_t\* score\_buffer\_sizes
);

CACTUS\_FFI\_EXPORT int cactus\_index\_compact(cactus\_index\_t index);
CACTUS\_FFI\_EXPORT void cactus\_index\_destroy(cactus\_index\_t index);

CACTUS\_FFI\_EXPORT const char\* cactus\_get\_last\_error(void);

// level: 0=DEBUG, 1=INFO, 2=WARN (default), 3=ERROR, 4=NONE
CACTUS\_FFI\_EXPORT void cactus\_log\_set\_level(int level);

typedef void (\*cactus\_log\_callback\_t)(int level, const char\* component, const char\* message, void\* user\_data);
CACTUS\_FFI\_EXPORT void cactus\_log\_set\_callback(cactus\_log\_callback\_t callback, void\* user\_data);

CACTUS\_FFI\_EXPORT void cactus\_set\_telemetry\_environment(const char\* framework, const char\* cache\_location, const char\* version);
CACTUS\_FFI\_EXPORT void cactus\_set\_app\_id(const char\* app\_id);
CACTUS\_FFI\_EXPORT void cactus\_telemetry\_flush(void);
CACTUS\_FFI\_EXPORT void cactus\_telemetry\_shutdown(void);

// cactus graph export
typedef void\* cactus\_graph\_t;
typedef uint64\_t cactus\_node\_t;

typedef struct {
 int32\_t precision;
 size\_t rank;
 size\_t shape\[8\];
 size\_t num\_elements;
 size\_t byte\_size;
} cactus\_tensor\_info\_t;

CACTUS\_FFI\_EXPORT cactus\_graph\_t cactus\_graph\_create(void);
CACTUS\_FFI\_EXPORT void cactus\_graph\_destroy(cactus\_graph\_t graph);
CACTUS\_FFI\_EXPORT int cactus\_graph\_hard\_reset(cactus\_graph\_t graph);

CACTUS\_FFI\_EXPORT int cactus\_graph\_save(cactus\_graph\_t graph, const char\* filename);
CACTUS\_FFI\_EXPORT cactus\_graph\_t cactus\_graph\_load(const char\* filename);

CACTUS\_FFI\_EXPORT int cactus\_graph\_input(
 cactus\_graph\_t graph, const size\_t\* shape, size\_t rank, int32\_t precision,
cactus\_node\_t\* out\_node);

CACTUS\_FFI\_EXPORT int cactus\_graph\_set\_input(
 cactus\_graph\_t graph, cactus\_node\_t node, const void\* data, int32\_t
precision);
CACTUS\_FFI\_EXPORT int cactus\_graph\_set\_external\_input(
 cactus\_graph\_t graph, cactus\_node\_t node, void\* data, int32\_t precision);

CACTUS\_FFI\_EXPORT int cactus\_graph\_precision\_cast(
 cactus\_graph\_t graph, cactus\_node\_t input, int32\_t target\_precision, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_add(cactus\_graph\_t graph, cactus\_node\_t a,
cactus\_node\_t b, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_add\_clipped(cactus\_graph\_t graph, cactus\_node\_t a,
cactus\_node\_t b, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_subtract(cactus\_graph\_t graph, cactus\_node\_t
a, cactus\_node\_t b, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_multiply(cactus\_graph\_t graph, cactus\_node\_t
a, cactus\_node\_t b, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_divide(cactus\_graph\_t graph, cactus\_node\_t
a, cactus\_node\_t b, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_add(cactus\_graph\_t graph, cactus\_node\_t x, float value, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_subtract(cactus\_graph\_t graph, cactus\_node\_t x, float value, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_multiply(cactus\_graph\_t graph, cactus\_node\_t x, float value, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_divide(cactus\_graph\_t graph, cactus\_node\_t x, float value, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_exp(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_sqrt(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_cos(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_sin(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scalar\_log(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_abs(cactus\_graph\_t graph, cactus\_node\_t x,
cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_pow(cactus\_graph\_t graph, cactus\_node\_t x,
float exponent, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_view(
 cactus\_graph\_t graph, cactus\_node\_t x, const size\_t\* shape, size\_t rank,
cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_flatten(
 cactus\_graph\_t graph, cactus\_node\_t x, int32\_t start\_dim, int32\_t end\_dim,
cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_reshape(
 cactus\_graph\_t graph, cactus\_node\_t x, const size\_t\* shape, size\_t rank, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_transpose(
 cactus\_graph\_t graph, cactus\_node\_t x, int32\_t backend, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_transpose\_n(
 cactus\_graph\_t graph, cactus\_node\_t x, const size\_t\* permutation, size\_t rank, int32\_t backend, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_slice(
 cactus\_graph\_t graph, cactus\_node\_t x, int32\_t axis, size\_t start, size\_t length, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_index(
 cactus\_graph\_t graph, cactus\_node\_t x, size\_t index\_value, int32\_t dim, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_sum(cactus\_graph\_t graph, cactus\_node\_t x, int32\_t axis, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_mean(cactus\_graph\_t graph, cactus\_node\_t x, int32\_t axis, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_variance(cactus\_graph\_t graph, cactus\_node\_t x, int32\_t axis, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_min(cactus\_graph\_t graph, cactus\_node\_t x, int32\_t axis, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_max(cactus\_graph\_t graph, cactus\_node\_t x, int32\_t axis, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_concat(
 cactus\_graph\_t graph, cactus\_node\_t a, cactus\_node\_t b, int32\_t axis,
cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_cat(
 cactus\_graph\_t graph, const cactus\_node\_t\* nodes, size\_t count, int32\_t
axis, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_matmul(
 cactus\_graph\_t graph, cactus\_node\_t a, cactus\_node\_t b, bool pretransposed\_rhs, int32\_t backend, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_gather(
 cactus\_graph\_t graph, cactus\_node\_t tensor, cactus\_node\_t indices, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_embedding\_from\_tensor(
 cactus\_graph\_t graph, cactus\_node\_t embedding\_tensor, cactus\_node\_t indices, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_embedding\_from\_file(
 cactus\_graph\_t graph, const char\* filename, cactus\_node\_t indices, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_mmap\_embeddings(
 cactus\_graph\_t graph, const char\* filename, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_mmap\_weights(
 cactus\_graph\_t graph, const char\* filename, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_bilinear\_interpolation(
 cactus\_graph\_t graph, cactus\_node\_t pos\_embeds, size\_t dst\_height, size\_t dst\_width, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_release\_weight\_pages(cactus\_graph\_t graph, cactus\_node\_t node);
CACTUS\_FFI\_EXPORT int cactus\_graph\_prefetch\_weight\_pages(cactus\_graph\_t graph, cactus\_node\_t node);
CACTUS\_FFI\_EXPORT int cactus\_graph\_release\_all\_weight\_pages(cactus\_graph\_t graph);

CACTUS\_FFI\_EXPORT int cactus\_graph\_relu(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_silu(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_gelu(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_gelu\_erf(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_sigmoid(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_tanh(cactus\_graph\_t graph, cactus\_node\_t x, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_glu(cactus\_graph\_t graph, cactus\_node\_t x, int32\_t axis, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_layernorm(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, cactus\_node\_t bias, float epsilon, bool has\_bias, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_groupnorm(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, cactus\_node\_t bias, size\_t num\_groups, float epsilon, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_batchnorm(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, cactus\_node\_t bias, cactus\_node\_t running\_mean, cactus\_node\_t running\_var, int32\_t axis, float epsilon, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_topk(cactus\_graph\_t graph, cactus\_node\_t input, size\_t k, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_rms\_norm(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, float epsilon, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_rope(
 cactus\_graph\_t graph, cactus\_node\_t input, float theta, size\_t position\_offset, int32\_t backend, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_rope\_gptj(
 cactus\_graph\_t graph, cactus\_node\_t input, float theta, size\_t position\_offset, size\_t rot\_dim, int32\_t backend, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_softmax(cactus\_graph\_t graph, cactus\_node\_t input, int32\_t axis, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_attention(
 cactus\_graph\_t graph, cactus\_node\_t query, cactus\_node\_t key, cactus\_node\_t value, float scale, bool is\_causal, size\_t position\_offset, size\_t window\_size, int32\_t backend, bool use\_mask, cactus\_node\_t mask, bool additive\_mask, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_rel\_pos\_bias(
 cactus\_graph\_t graph, cactus\_node\_t query, cactus\_node\_t relative\_key, float scale, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_attention\_int8\_hybrid(
 cactus\_graph\_t graph, cactus\_node\_t query, cactus\_node\_t key\_new, cactus\_node\_t value\_new, float scale, size\_t position\_offset,
 const int8\_t\* cached\_keys, const int8\_t\* cached\_values, const float\* k\_scales, const float\* v\_scales,
 size\_t cache\_len, size\_t num\_kv\_heads, size\_t head\_dim, size\_t window\_size, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_kv\_cache\_state(
 cactus\_graph\_t graph, size\_t max\_seq\_len, size\_t num\_kv\_heads, size\_t head\_dim, size\_t window\_size, size\_t sink\_size, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_kv\_cache\_append(
 cactus\_graph\_t graph, cactus\_node\_t new\_kv, cactus\_node\_t cache\_state, size\_t window\_size, size\_t sink\_size, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_attention\_cached(
 cactus\_graph\_t graph, cactus\_node\_t query, cactus\_node\_t key\_new, cactus\_node\_t value\_new,
 cactus\_node\_t k\_cache\_state, cactus\_node\_t v\_cache\_state,
 float scale, size\_t position\_offset, size\_t window\_size, size\_t v\_head\_dim, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_conv\_cache\_state(
 cactus\_graph\_t graph, size\_t window\_size, size\_t hidden\_dim, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv\_cache\_append(
 cactus\_graph\_t graph, cactus\_node\_t new\_data, cactus\_node\_t cache\_state, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_rfft(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_irfft(
 cactus\_graph\_t graph, cactus\_node\_t input, size\_t output\_length, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_mel\_filter\_bank(
 cactus\_graph\_t graph, size\_t num\_frequency\_bins, size\_t num\_mel\_filters,
 float min\_frequency, float max\_frequency, size\_t sampling\_rate,
 int norm\_type, int scale\_type, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_spectrogram(
 cactus\_graph\_t graph, cactus\_node\_t waveform, cactus\_node\_t mel\_filters,
 size\_t frame\_length, size\_t hop\_length, size\_t fft\_length,
 float power, bool center, int pad\_mode,
 float mel\_floor, int log\_mel\_mode,
 float dither, float preemphasis, bool remove\_dc\_offset,
 cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_image\_preprocess(
 cactus\_graph\_t graph, cactus\_node\_t pixel\_input,
 int src\_width, int src\_height, int target\_width, int target\_height,
 int patch\_size, int channels, float rescale\_factor,
 const float\* mean, const float\* std\_dev, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_conv1d\_causal(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, size\_t kernel\_size, size\_t dilation, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv1d\_k3(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, size\_t stride, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv1d\_k7s3(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, cactus\_node\_t bias, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv1d(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, bool has\_bias, cactus\_node\_t bias, size\_t stride, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv1d\_same\_depthwise\_k9(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, bool has\_bias, cactus\_node\_t bias, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv1d\_pointwise(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, bool has\_bias, cactus\_node\_t bias, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv2d\_k3s2p1(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, bool has\_bias, cactus\_node\_t bias, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv2d\_depthwise\_k3s2p1(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, bool has\_bias, cactus\_node\_t bias, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_conv2d\_pointwise\_1x1(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, bool has\_bias, cactus\_node\_t bias, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_lstm\_cell(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t h\_prev, cactus\_node\_t c\_prev, cactus\_node\_t weight\_ih, cactus\_node\_t weight\_hh, cactus\_node\_t bias\_ih, cactus\_node\_t bias\_hh, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_gated\_deltanet\_decode(
 cactus\_graph\_t graph, cactus\_node\_t query, cactus\_node\_t key, cactus\_node\_t value, cactus\_node\_t gate\_log, cactus\_node\_t beta, cactus\_node\_t initial\_state, float scale, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_gated\_deltanet\_prefill(
 cactus\_graph\_t graph, cactus\_node\_t query, cactus\_node\_t key, cactus\_node\_t value, cactus\_node\_t gate\_log, cactus\_node\_t beta, cactus\_node\_t initial\_state, size\_t chunk\_size, float scale, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_stft(
 cactus\_graph\_t graph, cactus\_node\_t input, cactus\_node\_t weight, size\_t stride, size\_t num\_fft\_bins, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_altup\_predict(
 cactus\_graph\_t graph, cactus\_node\_t coefs, const cactus\_node\_t\* streams, size\_t num\_streams, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_altup\_correct(
 cactus\_graph\_t graph, cactus\_node\_t coefs, cactus\_node\_t innovation, const cactus\_node\_t\* predictions, size\_t num\_predictions, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_gaussian\_topk(
 cactus\_graph\_t graph, cactus\_node\_t input, float ppf, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_moe\_layer\_gated(
 cactus\_graph\_t graph, cactus\_node\_t hidden, cactus\_node\_t routing\_probs, cactus\_node\_t topk\_indices,
 const cactus\_node\_t\* w1\_weights, const cactus\_node\_t\* w3\_weights, const cactus\_node\_t\* w2\_weights,
 size\_t num\_experts, size\_t num\_experts\_per\_tok, bool normalize\_routing, float epsilon, float routed\_scaling\_factor, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_moe\_layer\_ungated(
 cactus\_graph\_t graph, cactus\_node\_t hidden, cactus\_node\_t routing\_probs, cactus\_node\_t topk\_indices,
 const cactus\_node\_t\* w1\_weights, const cactus\_node\_t\* w2\_weights,
 size\_t num\_experts, size\_t num\_experts\_per\_tok, bool normalize\_routing, float epsilon, float routed\_scaling\_factor, int32\_t activation, cactus\_node\_t\* out);

CACTUS\_FFI\_EXPORT int cactus\_graph\_sample(
 cactus\_graph\_t graph, cactus\_node\_t logits, float temperature, float top\_p, size\_t top\_k, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_scatter\_topk(
 cactus\_graph\_t graph, cactus\_node\_t indices, cactus\_node\_t values, size\_t num\_classes, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_persistent(
 cactus\_graph\_t graph, cactus\_node\_t source\_node, cactus\_node\_t\* out);
CACTUS\_FFI\_EXPORT int cactus\_graph\_is\_populated(
 cactus\_graph\_t graph, cactus\_node\_t persistent\_node, int32\_t\* out\_is\_populated);
CACTUS\_FFI\_EXPORT int cactus\_graph\_invalidate\_persistent(
 cactus\_graph\_t graph, cactus\_node\_t persistent\_node);

CACTUS\_FFI\_EXPORT int cactus\_graph\_execute(cactus\_graph\_t graph);
CACTUS\_FFI\_EXPORT int cactus\_graph\_get\_output\_ptr(cactus\_graph\_t graph,
cactus\_node\_t node, void\*\* out\_ptr);
CACTUS\_FFI\_EXPORT int cactus\_graph\_get\_output\_info(cactus\_graph\_t graph,
cactus\_node\_t node, cactus\_tensor\_info\_t\* out\_info);

#ifdef \_\_cplusplus
}
#endif

#endif // CACTUS\_FFI\_H