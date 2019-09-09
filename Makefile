shared:
	cd src/github.com/asottile/dockerfile-dlang && \
	ldc2 -shared support.d && \
	cp libsupport.so ../../../../ && \
	go build -o libdockerfile.so -buildmode=c-shared main.go && \
	cp libdockerfile.so ../../../../ && \
	ldc2 -of ../../../../app app.d support.d -L-L. -L-ldockerfile -L='-R $$ORIGIN' -L='--enable-new-dtags' && \
	sudo cp lib*.so /usr/lib

