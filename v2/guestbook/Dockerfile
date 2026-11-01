# IBM Guestbook final project — multi-stage Docker build
FROM golang:1.25 AS builder
WORKDIR /app
COPY main.go .
RUN go mod init guestbook
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o guestbook main.go

FROM alpine:3.22
WORKDIR /app
COPY --from=builder /app/guestbook /app/guestbook
COPY public/index.html /app/public/index.html
COPY public/script.js /app/public/script.js
COPY public/style.css /app/public/style.css
COPY public/jquery.min.js /app/public/jquery.min.js
EXPOSE 3000
CMD ["./guestbook"]
