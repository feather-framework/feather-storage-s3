FROM swift:6.3

WORKDIR /app

COPY . ./

RUN swift package resolve

CMD ["swift", "test", "--parallel", "--enable-code-coverage"]
