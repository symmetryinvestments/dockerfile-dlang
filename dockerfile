FROM ubuntu:xenial
RUN echo hi > /etc/hi.conf
CMD ["echo"]
HEALTHCHECK --retries=5 CMD echo hi
ONBUILD ADD foo bar
ONBUILD RUN ["cat", "bar"]
