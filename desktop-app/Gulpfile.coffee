gulp = require 'gulp'
runSeq = require 'run-sequence'
OPTS = require('yargs').argv
$ = (require 'gulp-load-plugins')()

SRC = ['./bootstrap.js', 'src/**/*.js']
SPEC = 'test/**/*.spec.coffee'

gulp.task 'default', ['watch']

gulp.task 'watch', (done) ->
  gulp.watch SRC, [runSeq('build', 'test'), 'lint']
  done()

gulp.task 'build', -> $.run('npm run build:daemon -- --quiet').exec()

gulp.task 'lint', ->
  gulp.src SRC
    .pipe $.eslint('./.eslintrc.js')
    .pipe $.eslint.format()

gulp.task 'test', ->
  gulp.src SPEC, read: false
    .pipe $.spawnMocha
      compilers: ['coffee:coffee-script/register']
      require: ['source-map-support/register', 'dotenv/config']
      reporter: if OPTS.cover? then 'spec' else 'list'
      istanbul: if OPTS.cover?
        report: 'lcovonly'
