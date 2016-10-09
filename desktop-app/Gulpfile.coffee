gulp = require 'gulp'
runSeq = require 'run-sequence'
$ = (require 'gulp-load-plugins')()

JS_SRC = ['bootstrap.js', 'src/**/*.js']
CS_SRC = ['src/*.coffee']
GUI_SRC = ['src/gui/**']
LIB = ['../lib/js/src/**/*.js']
SPEC = 'test/**/*.spec.coffee'

gulp.task 'watch', (done) ->
  gulp.watch LIB, -> runSeq 'compile:lib', 'test', ->
  gulp.watch JS_SRC, -> runSeq 'compile:daemon', 'test', ->
  gulp.watch CS_SRC, -> runSeq 'compile:gui', 'test', ->
  gulp.watch GUI_SRC, ['gui:reload']
  $.livereload.listen()
  runSeq 'compile:all', 'test', ->
  done()

gulp.task 'test', ->
  gulp.src SPEC, read: false
    .pipe $.spawnMocha reporter: 'progress'
    .on 'error', $.notify.onError 'Some tests are failing'

gulp.task 'compile:all', ['compile:lib', 'compile:daemon', 'compile:gui']
gulp.task 'compile:lib', ['lint:lib'], -> compileJS LIB, './lib'
gulp.task 'compile:daemon', ['lint:daemon'], -> compileJS JS_SRC, './build'
gulp.task 'lint:lib', -> lintJS LIB
gulp.task 'lint:daemon', -> lintJS JS_SRC

gulp.task 'compile:gui', ['lint:gui'], ->
  gulp.src CS_SRC
    .pipe $.coffee sourceMaps: true
    .pipe gulp.dest './build'

gulp.task 'lint:gui', ->
  gulp.src './src/**/*.coffee'
    .pipe $.coffeelint '.coffeelint.json'
    .pipe $.coffeelint.reporter()

gulp.task 'gui:reload', ->
  gulp.src GUI_SRC
    .pipe $.changedInPlace firstPass: true
    .pipe $.livereload()

lintJS = (src) ->
  gulp.src src
    .pipe $.eslint('./.eslintrc.js')
    .pipe $.eslint.format()
    .pipe $.eslint.failAfterError()
    .on 'error', $.notify.onError 'JS code contains errors'

compileJS = (src, dst) ->
  gulp.src src
    .pipe $.changed dst, extension: '.js'
    .pipe $.sourcemaps.init()
    .pipe $.babel()
    .pipe $.sourcemaps.write '.'
    .pipe gulp.dest dst
