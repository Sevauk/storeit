gulp = require 'gulp'
browserSync = (require 'browser-sync').create()

SRC = './src/**'

gulp.task 'default', ['watch']

gulp.task 'build', (done) ->
  console.log 'build task: to do'
  done()

gulp.task 'watch', (done) ->
  browserSync.init
    proxy: 'http://localhost:3000'
    files: SRC
    port: 8888
  gulp.watch SRC, browserSync.stream()
  done()
