# Data-model sources

Use the highest-priority level that exists; read lower levels only to fill gaps and to detect drift. Tag every statement with its level's tag and the source path.

| Priority | Tag | Level | Patterns |
|---|---|---|---|
| 0 | EXTRACTED (dump, date) | User-provided schema dump | `.groma/schema/schema-*.sql` (written by `scripts/dump-schema.sh`, which the user runs) |
| 1 | EXTRACTED | Migrations | `**/migrations/**`, `**/db/migrate/**`, `**/db/migration/**` (`V*__*.sql`), `**/*.changelog.xml`/`.yaml` (Liquibase), `**/alembic/versions/*.py`, `**/Migrations/*.cs` (EF Core), `prisma/migrations/**/migration.sql`, `**/drizzle/*.sql`, `priv/repo/migrations/*.exs` (Ecto), `**/flyway/**/*.sql`, `knexfile.*` + `migrations/` |
| 2 | EXTRACTED | Schema files | `*.prisma`, `schema.sql`, `structure.sql`, `db/schema.rb`, `*.ddl`, `schema.graphql` (as data shape), `*.dbml`, `**/*.edmx`, `drizzle.config.*` + `schema.ts`, `supabase/migrations/**` |
| 3 | INFERRED | ORM / model code | `@Entity`, `@Table` (JPA/Hibernate), `models.Model` (Django), `declarative_base`, `Mapped[` (SQLAlchemy), `DbSet<` (EF Core), `@Entity()` (TypeORM), `mongoose.Schema`, `Schema(` (Mongoose), `schema "` (Ecto), `ActiveRecord::Base`/`ApplicationRecord`, `gorm.Model`, `#[derive(Queryable` (Diesel), `@Document` (Spring Data Mongo), `sequelize.define` |
| 4 | INFERRED | API and message contracts | `openapi.*`, `swagger.*`, `*.proto`, `*.avsc`, `asyncapi.*`, `*.schema.json`, GraphQL SDL |
| 5 | INFERRED | Code map | classes or types the code map shows as heavily referenced data holders |

## Rules

- **No database connections.** If no level 0-2 source exists and the project clearly has a database, offer the dump script: `sh <groma-survey>/scripts/dump-schema.sh postgres|mysql <db>|sqlite <file>` for the user to run.
- Prefer migrations over schema files over code. When two levels disagree, keep the higher level in the model and record the difference as **drift** with both paths.
- Describe the conceptual and logical model (entities, attributes that matter, relationships, invariants). Reference the physical schema files instead of copying DDL.
- No persistent data found and the user confirms: the data model is "Not applicable" with the reason.
