FROM badgerati/pode.web:latest-alpine
RUN pwsh -c "Install-Module PoshGram -Force; Install-Module pwshPlaces -Force"