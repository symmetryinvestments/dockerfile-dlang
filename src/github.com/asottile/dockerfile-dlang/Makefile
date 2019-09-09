shared:
	ldc2 -shared support.d
	go build -o libdockerfile.so -buildmode=c-shared main.go
	ldc2 app.d support.d -L-L. -L-ldockerfile

static:
	ldc2 -lib -static support.d -L-lphobos2-ldc -L-ldruntime-ldc -L-ldl "-defaultlib=phobos2-ldc,druntime-ldc"
	# ar -rcs libsupport.a support.o
	mv support.a libsupport.a
	go build --ldflags '-linkmode external -extldflags -static -L-lphobos2-ldc -L-ldruntime-ldc -L-ldl' main.go

