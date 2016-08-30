/*
 eslint-disable import/no-commonjs
*/
const
  express = require('express'),
  morgan = require('morgan')

let app = express()

app.use(morgan('dev'))
app.use(express.static('./src'))
app.use('/jspm_packages', express.static('./jspm_packages'))
app.use('/jspm.browser.js', express.static('./jspm.browser.js'))
app.use('/jspm.config.js', express.static('./jspm.config.js'))

app.all('/*', (req, res) => res.sendFile('src/index.html', {root: __dirname}))

app.listen(3000)
console.log('Express server listening on port 3000')
