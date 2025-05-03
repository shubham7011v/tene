Write-Host "Deploying Firebase rules to DEVELOPMENT environment" -ForegroundColor Yellow
firebase use dev
firebase deploy --only firestore:rules,storage:rules -c firebase.dev.json 