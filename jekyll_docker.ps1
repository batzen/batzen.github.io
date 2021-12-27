Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet('build', 'serve', 'update')]
    [string]$Mode = 'serve'
)

if (Get-Command docker-volume-watcher -ErrorAction SilentlyContinue) {
    Write-Host "Starting docker volume watcher..."
    $process = Start-Process -FilePath docker-volume-watcher -WindowStyle Minimized -PassThru
    Write-Host "Stared docker volume watcher."
}

$env:JEKYLL_SITE_DIR = $PWD
$env:DOCKER_IMAGE_NAME = "jekyll/jekyll:latest"

if (-Not (Get-Variable JEKYLL_SITE_DIR -Scope Global -ErrorAction SilentlyContinue) -and !($env:JEKYLL_SITE_DIR)) {
    Write-Host "`$env:JEKYLL_SITE_DIR was not defined."
    $env:JEKYLL_SITE_DIR = "$PWD"
}

$env:JEKYLL_SITE_DIR = $env:JEKYLL_SITE_DIR -replace "\\", "/"
$volume = "$($env:JEKYLL_SITE_DIR):/srv/jekyll"
$cacheHostPath = "$($env:JEKYLL_SITE_DIR)/vendor/bundle"
$cacheVolume = "$($cacheHostPath):/usr/local/bundle"

Write-Host "`$env:JEKYLL_SITE_DIR: $env:JEKYLL_SITE_DIR"
Write-Host "`$env:DOCKER_IMAGE_NAME: $env:DOCKER_IMAGE_NAME"
Write-Host "`$volume: $volume"

if (!(Test-Path $cacheHostPath)) {
    New-Item $cacheHostPath -ItemType Directory | Out-Null
}

if ($Mode -ieq "build") {
    $jekyllCommand = "jekyll build"
}
elseif ($Mode -ieq 'serve') {
    $jekyllCommand = "jekyll serve --watch --force_polling"
}
elseif ($Mode -ieq 'update') {
    $jekyllCommand = "bundle update"
}

$dockerCommand = "ls && bundle install && jekyll --version && ruby --version && $jekyllCommand"

Write-Host $dockerCommand

docker run `
-e TZ=Europe/Berlin `
--volume=$volume `
--volume=$cacheVolume `
--publish 4000:4000 `
-it $env:DOCKER_IMAGE_NAME `
bash -c $dockerCommand

if ($process) {
    Write-Host "Stopping docker volume watcher..."
    $process.Kill()
    Write-Host "Stopped docker volume watcher."
}