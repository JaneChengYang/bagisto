#!/bin/bash
set -e
php artisan migrate --force --seed
exec apache2-foreground
