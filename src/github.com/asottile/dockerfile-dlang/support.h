#define size_t long long
void* stringSlice(size_t length);
void* commandSlice(size_t length);
void setStringElement(void* sliceV, size_t i, char* s);
void setCommandElement(void* sliceV,size_t i, void* p);
void* command(char* cmd, char* sub_cmd, int json, char* original, int start_line, int end_line, void* flags, void* value);
void* raise(char* errorMessage);
void* return_success(void* ret);
