Write-Host "Deploying Firebase rules to PRODUCTION environment" -ForegroundColor Green
firebase use prod
firebase deploy --only firestore:rules,storage:rules -c firebase.prod.json 