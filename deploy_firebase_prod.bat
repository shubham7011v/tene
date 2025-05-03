@echo off
echo Deploying Firebase rules to PRODUCTION environment
firebase use prod
firebase deploy --only firestore:rules,storage:rules -c firebase.prod.json 