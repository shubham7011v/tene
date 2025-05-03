# Firebase Rules Management for Multi-Environment Setup

This document explains how to manage Firebase security rules for different environments in the Tene app.

## Rule Files

The project includes separate rule files for each environment:

- `firestore.rules.dev` - Firestore rules for the development environment
- `firestore.rules.prod` - Firestore rules for the production environment
- `storage.rules` - Firebase Storage rules (shared between environments)
- `firestore.indexes.json` - Firestore indexes for both environments

## Key Differences Between Environments

### Development Environment

The development environment has more permissive rules:
- Includes a special `/dev_data/{document=**}` collection that allows authenticated users to read/write any documents (for testing)
- Less strict validation on document creation

### Production Environment

The production environment has stricter rules:
- No test collections with permissive access
- Stricter data validation (required fields, field types)
- No emulator configuration

## Deploying Rules

### Using Scripts

For convenience, deployment scripts are provided:

**Windows CMD:**
```
deploy_firebase_dev.bat   # Deploy to development
deploy_firebase_prod.bat  # Deploy to production
```

**PowerShell:**
```
./deploy_firebase_dev.ps1 # Deploy to development
./deploy_firebase_prod.ps1 # Deploy to production
```

### Manual Deployment

You can also deploy rules manually:

```bash
# Deploy to development
firebase use dev
firebase deploy --only firestore:rules,storage:rules -c firebase.dev.json

# Deploy to production
firebase use prod
firebase deploy --only firestore:rules,storage:rules -c firebase.prod.json
```

## Testing Rules

To test rules before deployment:

1. Use the Firebase Emulator Suite:
   ```
   firebase emulators:start -c firebase.dev.json
   ```

2. Write and run security rule tests:
   ```
   firebase emulators:exec --only firestore "npm test"
   ```

## Best Practices

1. **Always test rules before deployment to production**
2. **Keep development and production rules in sync** - When adding new collections or changing access patterns, update both rule files
3. **Use the rule files as documentation** - Document the data model and access patterns in comments
4. **Version control the rule files** - Track changes to rules over time
5. **Test rules with different user scenarios** - Ensure rules work for all user roles and edge cases

## Rule Structure

### Firestore Rules

Both development and production rules follow a similar structure:
- User data access rules (users can only access their own data)
- Tene collection rules (sender and recipient permissions)
- Default deny rule (secure by default)

### Storage Rules

Storage rules allow:
- Users to upload and manage their profile data
- Users to share tene media with recipients
- Size and content type validation 