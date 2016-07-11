exec = require('child_process').exec

module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-contrib-watch')
  coffee = [
    'public/d/js/*.coffee'
  ]
  coffee_command = "coffee -m -c"
  sass_command = "cd public/d && compass compile --sourcemap sass/screen.sass"
  exec_callback = (error, stdout, stderr)->
    if error
      console.log('exec error: ' + error)

  grunt.registerTask 'compile', ->
    for file in coffee
      exec("#{coffee_command} #{file}", exec_callback)
    exec("mkdir public/d/css", exec_callback)
    exec(sass_command, exec_callback)

  grunt.initConfig
    watch:
      coffee:
        files: coffee
      sass:
        files: 'public/d/sass/screen.sass'
      static:
        files: ['public/d/**/*.css',
          'public/**/*.html',
          'public/**/*.js'],
        options:
          livereload: true
    compile:
      coffee:
        files: coffee

  grunt.event.on 'watch', (event, file, ext)->
    if ext == 'coffee'
#      console.info("compiling: #{file}")
      exec("#{coffee_command} #{file}", exec_callback)
    if ext == 'sass'
#      console.info("compiling: #{file}")
      exec(sass_command, exec_callback)

  grunt.registerTask('default', ['watch'])