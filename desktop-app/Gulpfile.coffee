gulp = require 'gulp'
eslint = require 'gulp-eslint'

SRC = 'src/*.js'

gulp.task 'default', ['watch:lint']

gulp.task 'watch:lint', (done) ->
  gulp.watch SRC, ['lint']
  done()

gulp.task 'lint', ->
  gulp.src SRC
    .pipe eslint('./.eslintrc.js')
    .pipe eslint.format()
