# Stage 1: Build dependencies
FROM ruby:3.2.2-alpine AS builder

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    tzdata \
    curl

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config --global frozen 1 && \
    bundle install --without development test --jobs 4 --retry 3

COPY . .

RUN bundle exec rake assets:precompile 2>/dev/null || true

# Stage 2: Production image
FROM ruby:3.2.2-alpine AS production

RUN apk add --no-cache \
    postgresql-client \
    tzdata \
    curl \
    && addgroup -g 1000 -S appgroup \
    && adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=appuser:appgroup /app .

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
