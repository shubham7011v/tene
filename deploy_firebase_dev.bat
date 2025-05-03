@echo off
echo Deploying Firebase rules to DEVELOPMENT environment
firebase use dev
firebase deploy --only firestore:rules,storage:rules -c firebase.dev.json 