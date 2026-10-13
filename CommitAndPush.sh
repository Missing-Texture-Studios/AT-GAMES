#!/bin/bash

echo "Enter commit message:"
read -r commit_message

if [ -z "$commit_message" ]; then
    echo "Error: Commit message cannot be empty."
    exit 1
fi

git add . || exit 1
git commit -m "$commit_message" || exit 1
git push origin main --force || exit 1

echo "Done!"
read -r -p "Press Enter to exit..."

