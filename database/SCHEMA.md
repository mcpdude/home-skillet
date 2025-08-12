# Home Skillet Database Schema Documentation

## Overview

The Home Skillet database is designed with a multi-tenant architecture using property-based isolation. This ensures that users only have access to data for properties where they have been granted explicit permissions.

## Core Design Principles

1. **Multi-Tenant Architecture**: Property-based data isolation ensures secure access control
2. **Granular Permissions**: Role-based permissions with fine-grained control over features
3. **Audit Trail**: All tables include created/updated timestamps and modification tracking
4. **Extensibility**: JSON columns allow for flexible data storage and future feature expansion
5. **Performance**: Comprehensive indexing strategy for common query patterns
6. **Data Integrity**: Foreign key constraints and check constraints maintain data quality

## Database Tables

### Core Entities

#### users
Primary user account table for authentication and profile management.

**Key Features:**
- UUID primary keys for security
- Support for multiple authentication providers (local, OAuth)
- Email verification and account status tracking
- User preferences stored as JSON for flexibility
- Timezone and language preferences

**Important Columns:**
- `email`: Unique identifier, used for login
- `provider`: Authentication method ('local', 'google', 'apple', etc.)
- `is_active`: Account status flag
- `preferences`: JSON field for user settings

#### properties
Property information and details for multi-tenant isolation.

**Key Features:**
- Complete address information with geocoding support
- Property characteristics (type, size, year built, etc.)
- Financial information (purchase price, assessed value)
- Utility and insurance information stored as JSON
- Property features and appliances stored as JSON
- Media storage (photos, floor plans)

**Multi-Tenant Key:**
- All data access is filtered by property_id
- Users must have roles assigned to access property data

#### user_property_roles
Multi-tenant permission system - core table for access control.

**Key Features:**
- Links users to properties with specific roles
- Granular permissions stored as JSON
- Invitation system for adding users to properties
- Time-limited access support
- Role-based permission templates

**Roles:**
- `owner`: Full administrative control
- `family`: Configurable permissions per property  
- `contractor`: Limited access to assigned projects
- `tenant`: Access to maintenance requests and property info
- `realtor`: Read-only access to property history

**Permission Structure:**
```json
{
  "projects": {
    "view_all": true/false,
    "create": true/false,
    "edit": true/false,
    "delete": true/false,
    "assign": true/false
  },
  "maintenance": {
    "view_schedules": true/false,
    "manage_schedules": true/false,
    "view_records": true/false,
    "create_records": true/false
  },
  "documents": {
    "view_all": true/false,
    "upload": true/false,
    "delete": true/false,
    "share": true/false
  },
  "financial": {
    "view_summary": true/false,
    "view_detailed": true/false,
    "manage_budgets": true/false
  },
  "vendors": {
    "view": true/false,
    "manage": true/false,
    "contact": true/false
  },
  "property": {
    "view_details": true/false,
    "edit_details": true/false,
    "manage_users": true/false
  }
}
```

### Project Management

#### projects
Home improvement and maintenance projects.

**Key Features:**
- Comprehensive project tracking (status, progress, timeline)
- Financial tracking (estimates, actuals, budgets)
- Location and scope information
- Material and tool requirements
- Photo documentation (before, during, after)
- Project relationships (parent/child, dependencies)
- Quality ratings and warranty information

**Status Flow:**
`not_started` → `planning` → `in_progress` → `on_hold` → `completed` / `cancelled`

#### tasks
Individual tasks within projects (Phase 1 MVP - task lists).

**Key Features:**
- Task ordering within projects
- Individual task assignments
- Time and cost tracking per task
- Task dependencies
- Quality control and verification
- Photo and document attachments per task

#### project_assignments
Project assignment and delegation system.

**Key Features:**
- Assign projects to users or vendors
- Role-based assignment (lead, contributor, reviewer, etc.)
- Performance tracking and ratings
- Time and availability management
- Contract and deliverable tracking for vendors

### Maintenance Management

#### maintenance_schedules
Recurring maintenance task definitions.

**Key Features:**
- Flexible scheduling (intervals, seasonal, custom)
- Detailed instructions and safety notes
- Material and tool requirements
- Automated reminder system
- Performance tracking (completion rates, costs)
- Professional vs. DIY classification

**Frequency Types:**
- `days`, `weeks`, `months`, `years`: Regular intervals
- `seasonal`: Specific seasons
- `custom`: Complex scheduling patterns

#### maintenance_records
Completed maintenance work history.

**Key Features:**
- Links to maintenance schedules or ad-hoc work
- Personnel tracking (performed by, supervised by)
- Financial tracking with payment methods
- Quality ratings and outcomes
- Follow-up requirements
- Before/after condition tracking
- Photo documentation

### Document Management

#### documents
File storage metadata (files stored in S3).

**Key Features:**
- S3 integration with signed URLs
- OCR text extraction for searchability
- Version control and document relationships
- Flexible categorization and tagging
- Access control and sharing permissions
- Expiration tracking for warranties/permits
- Financial document support (receipts, invoices)

**Document Categories:**
- `warranty`, `receipt`, `manual`, `permit`, `insurance`, `deed`, `survey`, `photo`, `video`

### Vendor Management

#### vendors
Service provider information and management.

**Key Features:**
- Complete contact and business information
- License and insurance tracking
- Service categories and specializations
- Performance metrics and ratings
- Pricing and payment terms
- Certification and credential tracking
- Service area and availability
- Communication preferences

### Supporting Tables

#### project_assignments
Links projects to users and vendors with role definitions.

#### Additional Indexes
Performance optimization indexes for common query patterns.

## Data Types and Storage

### JSON Columns
Used extensively for flexible data storage:
- User preferences and settings
- Property features and appliances
- Permission configurations
- Material and tool lists
- Photo and document arrays
- Vendor certifications and capabilities

### UUID Primary Keys
All tables use UUID primary keys for:
- Security (non-sequential, non-guessable)
- Distributed system compatibility
- Cross-database portability

### Audit Columns
Standard audit trail on all tables:
- `created_at`: Automatic timestamp on insert
- `updated_at`: Automatic timestamp on update
- `created_by_user_id`: User who created the record
- `last_modified_by`: User who last modified the record

## Indexing Strategy

### Primary Indexes
- All tables have UUID primary key indexes
- Unique constraints on email addresses and user-property role combinations

### Performance Indexes
- Property-based filtering (multi-tenant isolation)
- Status and category filtering
- Date range queries
- User assignments and relationships
- Full-text search on extracted document text

### Composite Indexes
Strategic composite indexes for common query patterns:
- `property_id + status + priority` for project dashboards
- `property_id + category + date` for maintenance history
- `user_id + is_active` for user property access

## Multi-Tenant Security

### Property-Based Isolation
All data access must be filtered by property_id where the user has appropriate permissions.

### Permission Checking
1. Verify user has role on property
2. Check role is active (`is_active = true`)
3. Verify specific permission for requested action
4. Check for time-limited access expiration

### Data Access Patterns
```sql
-- Example: Get user's projects
SELECT p.* 
FROM projects p
JOIN user_property_roles upr ON p.property_id = upr.property_id
WHERE upr.user_id = ? 
  AND upr.is_active = true
  AND upr.permissions->>'projects'->>'view_all' = 'true'
```

## Migration Strategy

### File Naming Convention
`XXX_descriptive_name.js` where XXX is sequential number (001, 002, etc.)

### Dependency Order
1. Core user and property tables
2. Permission and role tables  
3. Feature tables (projects, maintenance, etc.)
4. Relationship and assignment tables
5. Performance indexes

### Rollback Safety
All migrations include complete `down()` functions for safe rollback.

## Performance Considerations

### Query Optimization
- Always filter by property_id first
- Use appropriate indexes for date ranges and status filters
- Leverage composite indexes for multi-column filters

### JSON Query Performance
- PostgreSQL GIN indexes on JSON columns for fast searches
- Structured JSON schemas for consistent querying

### Connection Pooling
Knex configuration includes connection pooling for optimal performance.

## Testing Strategy

### Schema Tests
- Table existence and structure validation
- Foreign key constraint verification
- Index existence and functionality
- Data type and constraint validation

### Seed Data Tests
- Referential integrity verification
- Multi-tenant data isolation testing
- Permission system validation
- Data consistency checks

### Migration Tests
- Up/down migration testing
- Migration dependency validation
- Default value verification
- Constraint enforcement testing

## Future Considerations

### Phase 2 Enhancements
- Advanced project management (phases, milestones, dependencies)
- Integration capabilities with external systems
- Advanced reporting and analytics tables
- Real-time collaboration features

### Scalability
- Read replica support for reporting
- Partitioning strategies for large datasets
- Caching layer integration points

### Data Retention
- Archive strategies for completed projects
- Document retention policies
- Performance data aggregation tables