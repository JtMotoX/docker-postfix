FROM alpine:latest as base_image

###################################

FROM base_image as builder_image

RUN apk add --no-cache openssl
RUN mkdir -p /ssl/certs /ssl/private && \
	openssl req -new -x509 -days 3650 -nodes -sha256 \
	-subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
	-out /ssl/certs/smtpd.pem \
	-keyout /ssl/private/smtpd.key 

###################################

FROM base_image as final_image

RUN apk add --no-cache postfix mailx

COPY --from=builder_image /ssl /etc/ssl

RUN postalias /etc/postfix/aliases

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
CMD ["/entrypoint.sh"]
