gulp = require 'gulp'
coffee = require 'gulp-coffee'
gutil = require 'gulp-util'
sass = require 'gulp-ruby-sass'
concat = require 'gulp-concat'
mocha = require 'gulp-mocha'
preprocess = require 'gulp-preprocess'
git = require 'gulp-git'
fs = require 'fs'

gulp.task 'default', ['mocha']

gulp.task 'mocha', ->
  gulp.src(['test/*.coffee'], { read: false })
    .pipe(mocha(ui: 'tdd'))
    .on('error', gutil.log)

gulp.task 'dist', ->
  gulp.src(['src/lib/*.coffee', 'src/*.coffee'])
    .pipe(coffee(bare: true))
    .pipe(concat('jquery.jsonview.js'))
    .pipe(gulp.dest('dist'))

  gulp.src('src/*.scss')
    .pipe(sass())
    .pipe(gulp.dest('dist'))

  gulp.src('src/index.html')
    .pipe(preprocess(context: { dist: true }))
    .pipe(gulp.dest('dist'))

gulp.task 'build', ->
  gulp.src('src/**/*.coffee')
    .pipe(coffee(bare: true))
    .pipe(gulp.dest('build'))

  gulp.src('src/*.scss')
    .pipe(sass())
    .pipe(gulp.dest('build'))

  gulp.src('src/index.html')
    .pipe(preprocess(context: { dist: false }))
    .pipe(gulp.dest('build'))

gulp.task 'watch', ->
  gulp.watch('src/**/*', ['build', 'dist', 'mocha'])

gulp.task 'package', ->
  data = fs.readFileSync 'package.json', 'utf8'
  pkg = JSON.parse(data)
  # jquery.json
  json1 =
    name: pkg.name,
    description: pkg.description,
    version: pkg.version,
    author: pkg.author,
    keywords: pkg.keywords,
    homepage: pkg.homepage
  json2 = pkg.jqueryJSON
  json1[key] = json2[key] for key of json2
  fs.writeFile 'jsonview.jquery.json', JSON.stringify(json1, null, 2)

  # bower.json
  json1 =
    name: pkg.name,
    description: pkg.description,
    version: pkg.version,
    main: pkg.main
    keywords: pkg.keywords,
    license: pkg.license,
    homepage: pkg.homepage
  json2 = pkg.bowerJSON
  json1[key] = json2[key] for key of json2
  fs.writeFile 'bower.json', JSON.stringify(json1, null, 2)

gulp.task 'release', ['dist', 'package'], ->
  data = fs.readFileSync 'package.json', 'utf8'
  pkg = JSON.parse(data)
  git.tag("v#{pkg.version}")
  git.push('origin', 'master', {args: ' --tags'})
  exec('npm publish')

