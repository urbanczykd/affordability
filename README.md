# Mortgage Affordability API

A production-ready Rails 7.2 API service that evaluates mortgage applications against standard affordability criteria. Applications are processed asynchronously via Sidekiq, and callers poll for results.

---
## Fast and Simple option

- git clone https://github.com/urbanczykd/affordability
- cd affordability
- docker compose up --build
- rbenv install 3.2.2 
- rbenv shell 3.2.2
- bundle install
- bundle exec rails db:create:all db:migrate
- bundle exec rspec
# if all tests are green this means that db,app,redis and db
has to be up also and the application should be accessible under 
- http://localhost:3000/
# Sidekiq UI is available under http://localhost:9292/


# run tests

## Setup & Running

### Prerequisites

- Ruby 3.2.2
- PostgreSQL 14+
- Redis 7+
- Bundler 2.x

### Local development (without Docker)

```bash
# 1. Clone the repository and install dependencies
git clone https://github.com/urbanczykd/affordability
cd affordability
bundle install

# X. Configure environment
# .env is commited into scm, it shoudn't be but it's easier to 
# run the application in dev or run tests
# cp .env.example .env
# Edit .env and set API_KEY, DATABASE_URL, REDIS_URL

# 2. for rbenv
rbenv shell 3.2.2
# if ruby 3.2.2 isn't installed run rbenv install 3.2.2 
# 3. Create and migrate the database
bundle exec rails db:create db:migrate

# 4. Start the Rails server
bundle exec rails s

# 5. In a separate terminal, start Sidekiq
bundle exec sidekiq -q default
```

### Docker Compose (recommended)

```bash
# cp .env.example .env
# Set a strong API_KEY in .env

docker compose up --build
```

This starts PostgreSQL, Redis, the Rails API on port 3000, and a Sidekiq worker.

The database is migrated automatically on first start of the `app` service.

### Running tests

```bash
# Ensure a test database is available
DATABASE_URL_TEST=postgresql://localhost/affordability_test bundle exec rails db:create db:migrate RAILS_ENV=test

# Run the full test suite
bundle exec rspec

# Run a specific file
bundle exec rspec spec/services/affordability_calculator_spec.rb
```

---

## API Reference

All endpoints require a Bearer token in the `Authorization` header:

```
Authorization: Bearer <API_KEY>
```

### Create a mortgage application

```
POST /api/v1/mortgage_applications
```

**Request body**

```json
{
  "mortgage_application": {
    "annual_income": 75000,
    "monthly_expenses": 1500,
    "deposit_amount": 50000,
    "property_value": 350000,
    "term_years": 25
  }
}
```

**curl example**

```bash
curl -s -X POST http://localhost:3000/api/v1/mortgage_applications \
  -H "Authorization: Bearer dev-secret-key-change-in-production" \
  -H "Content-Type: application/json" \
  -d '{
    "mortgage_application": {
      "annual_income": 75000,
      "monthly_expenses": 1500,
      "deposit_amount": 50000,
      "property_value": 350000,
      "term_years": 25
    }
  }' | jq .
```

**Response 201 Created**

```json
{
  "id": "fe4f1f57-4666-4388-b70c-32122f76f0dc",
  "annual_income": "75000.0",
  "monthly_expenses": "1500.0",
  "deposit_amount": "50000.0",
  "property_value": "350000.0",
  "term_years": 25,
  "created_at": "2026-04-15T10:00:00.000Z",
  "updated_at": "2026-04-15T10:00:00.000Z"
}
```

---

### Retrieve a mortgage application

```
GET /api/v1/mortgage_applications/:id
```

**curl example**

```bash
curl -s http://localhost:3000/api/v1/mortgage_applications/693f3f3d-12a2-405c-ab4f-95c0fa5b3d96 \
  -H "Authorization: Bearer dev-secret-key-change-in-production" | jq .
```

**Response 200 OK** — same shape as create response.

---

### Trigger an affordability assessment

```
POST /api/v1/mortgage_applications/:mortgage_application_id/assessments
```

Enqueues an async Sidekiq job and immediately returns the new assessment in `pending` state.

**curl example**

```bash
curl -s -X POST \
  http://localhost:3000/api/v1/mortgage_applications/693f3f3d-12a2-405c-ab4f-95c0fa5b3d96/assessments \
  -H "Authorization: Bearer dev-secret-key-change-in-production" | jq .
```

**Response 202 Accepted**

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "mortgage_application_id": "fe4f1f57-4666-4388-b70c-32122f76f0dc",
  "status": "pending",
  "decision": null,
  "loan_amount": null,
  "ltv": null,
  "dti_ratio": null,
  "max_borrowing": null,
  "monthly_payment": null,
  "explanation": null,
  "created_at": "2026-04-15T10:00:01.000Z",
  "updated_at": "2026-04-15T10:00:01.000Z"
}
```

---

### Poll assessment status and result

```
GET /api/v1/mortgage_applications/:mortgage_application_id/assessments/:id
```

Poll until `status` is `"completed"` or `"failed"`. A reasonable polling interval is 1–2 seconds.

**curl example**

```bash
curl -s \
  http://localhost:3000/api/v1/mortgage_applications/693f3f3d-12a2-405c-ab4f-95c0fa5b3d96/assessments/b2c3d4e5-f6a7-8901-bcde-f12345678901 \
  -H "Authorization: Bearer dev-secret-key-change-in-production" | jq .
```

**Response 200 OK (completed — approved)**

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "mortgage_application_id": "fe4f1f57-4666-4388-b70c-32122f76f0dc",
  "status": "completed",
  "decision": "approved",
  "loan_amount": "300000.0",
  "ltv": "85.7143",
  "dti_ratio": "24.0000",
  "max_borrowing": "315000.0",
  "monthly_payment": "1501.67",
  "explanation": "Application approved. Loan amount of £300000.00 with LTV of 85.7% and DTI ratio of 24.0% meets all lending criteria.",
  "created_at": "2026-04-15T10:00:01.000Z",
  "updated_at": "2026-04-15T10:00:02.000Z"
}
```

**Response 200 OK (completed — declined)**

```json
{
  "status": "completed",
  "decision": "declined",
  "explanation": "Application declined. Loan-to-value ratio of 97.1% exceeds the maximum allowed 90%."
}
```

---

### Error responses

| HTTP status               | Cause                                    |
|---------------------------|------------------------------------------|
| 400 Bad Request           | Missing required parameter key           |
| 401 Unauthorized          | Missing or invalid Bearer token          |
| 404 Not Found             | Application or assessment ID not found   |
| 422 Unprocessable Entity  | Validation errors on the submitted data  |
| 500 Internal Server Error | Unconfigured API_KEY or unexpected error |

Error body:

```json
{ "error": "Validation failed", "messages": ["Annual income must be greater than 0"] }
```

---

## Design Decisions

### 1. Async assessment processing via Sidekiq

Affordability calculations are deliberately performed outside the HTTP request cycle. When a client calls `POST .../assessments`, the API creates an `Assessment` record in `pending` state, enqueues an `AffordabilityAssessmentJob`, and returns 202. The client polls the GET endpoint until `status` transitions to `completed` or `failed`.

This separation matters because affordability processing is expected to become more expensive over time — integrating with credit bureaus, running statistical models, or aggregating third-party data. By decoupling computation from the request path from day one, none of those integrations require an API contract change; only the internals of the job and the calculator change. It also naturally handles traffic spikes: requests are accepted immediately and workers drain the queue at their own pace, making the system horizontally scalable at the worker tier independently from the web tier.

### 2. Service object pattern (AffordabilityCalculator)

All affordability logic lives in `AffordabilityCalculator`, a plain Ruby object with a single public method `#calculate` that returns a typed `Result` struct. No business logic appears in a controller, model callback, or job body. The job is a thin orchestrator: it fetches the record, delegates to the service, and persists results.

This matters for two reasons. First, it makes the calculation independently testable — no database, no HTTP stack, no factories required. Second, it establishes a clear seam: the rules in the calculator can be replaced, parameterised, or versioned without touching the HTTP layer. When a lender uploads a new rate table or adjusts DTI thresholds, the change is confined to one class with one well-defined responsibility.

### 3. UUID primary keys

Both `mortgage_applications` and `assessments` use UUID v4 primary keys generated by PostgreSQL's `pgcrypto` extension (`gen_random_uuid()`). Sequential integer IDs expose record counts to clients and are easily enumerated. UUIDs prevent ID enumeration attacks, allow records to be pre-generated before database insertion (useful for event sourcing or distributed ID generation), and are safe to include in URLs without revealing business intelligence. The trade-off — slightly larger index size and a marginal write overhead — is negligible at the scale this service targets.

---

## System Evolution

### Service boundaries

As the domain grows, the affordability calculation is the natural first extraction candidate. The `AffordabilityCalculator` class already encapsulates a bounded context. When complexity justifies it, it can become an internal microservice or a serverless function invoked by the job. The job's interface — receive an `assessment_id`, compute, and write back — remains the same; only the calculator invocation changes.

If the mortgage application lifecycle gains new states (underwriting, document collection, broker review) each deserves its own model, its own job, and potentially its own service. The pattern established here — API accepts, validates, delegates asynchronously, client polls — scales to orchestrated multi-step workflows. Replacing polling with webhooks or server-sent events is a localised change: swap the GET endpoint for a push mechanism without changing how applications are created or how jobs compute results.

### Load handling

The web tier (Puma) and the worker tier (Sidekiq) scale independently. Under sustained load, adding Sidekiq processes or containers with `--concurrency` tuned to the workload is sufficient. If a downstream calculation step becomes I/O-bound (e.g., waiting on a credit bureau API), Sidekiq's thread-per-job model handles concurrency well. If it becomes CPU-bound, running multiple single-threaded worker processes may be preferable to a single highly-concurrent process.

The PostgreSQL schema uses a UUID index on `assessments.mortgage_application_id` and a status index on `assessments.status`. These support the two dominant query patterns: retrieve all assessments for an application (polling), and monitoring queries that count pending assessments (operations dashboards). At higher volume, partitioning assessments by `created_at` or archiving completed records older than N days are straightforward schema evolutions.

### Async patterns

The current polling model is the simplest correct implementation. For clients that cannot poll (batch processors, mobile apps with unreliable connectivity), adding a webhook callback URL field to the assessment creation request is a non-breaking change. The job would POST results to the callback URL after writing to the database, and the polling endpoint continues to work for clients that prefer it.

---

## Operational Considerations

### Failure handling

`AffordabilityAssessmentJob` uses `retry_on StandardError, wait: :polynomially_longer, attempts: 3`. On the third failure the job is moved to Sidekiq's dead-letter queue and the assessment is marked `failed`. This means clients polling on a failed assessment receive a definitive terminal state rather than waiting forever.

The dead-letter queue in the Sidekiq Web UI provides visibility into failed jobs with full error backtraces and the ability to retry or discard them. In production, a Sidekiq error notifier (e.g., integration with Sentry, Honeybadger, or Bugsnag via `sidekiq-failures`) should be wired to alert on any job entering the dead queue.

### Monitoring

Critical metrics to instrument and alert on:

- **Sidekiq queue depth** — a growing `default` queue indicates workers cannot keep up. Alert if depth exceeds a threshold consistent with your SLA.
- **Job latency** — time between enqueue and execution. High latency means workers are saturated.
- **Assessment completion rate** — what fraction of assessments reach `completed` vs `failed`. A spike in failures may indicate a data quality problem upstream.
- **API error rates by status code** — distinguish 4xx (client error, generally not actionable by ops) from 5xx (server error, must alert).
- **Database connection pool saturation** — monitored via `ActiveRecord::ConnectionAdapters::ConnectionPool#stat`.

### Data integrity

The database enforces non-null constraints and a foreign key from `assessments` to `mortgage_applications`. The `status` field has a default of `pending` at the database level, not only in the application, so direct database inserts cannot produce a statusless row.

Assessments are scoped through their parent in the `AssessmentsController` (`@mortgage_application.assessments.find(...)`) so one tenant can never read or interact with another's assessments, even if assessment IDs were somehow guessed.

---

## Change & Flexibility

### Externalized affordability rules

The constants in `AffordabilityCalculator` — `MAX_LTV`, `MAX_DTI`, `INCOME_MULTIPLE`, and `ASSUMED_ANNUAL_RATE` — are currently hard-coded in the class. Externalizing them is a single-step change:

1. Add a `LendingPolicy` model (or read from a YAML config) that stores the active thresholds.
2. Pass the policy object into `AffordabilityCalculator.new(application, policy: LendingPolicy.current)`.
3. The constructor assigns the policy's values to instance variables; the rest of the code is unchanged.

This pattern also enables A/B testing different lending criteria, time-limited promotional rates (e.g., a 95% LTV product for first-time buyers), or per-broker policy overrides — all without branching in the calculator itself.

### Versioned API

The namespace `Api::V1` anticipates future versions. When the assessment response shape needs to change (e.g., adding more granular decline reasons or a risk score), a `V2::AssessmentsController` can inherit from `V1` and override only the serializer, leaving V1 clients unaffected until they migrate.
