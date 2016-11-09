import fs from 'fs'

let sets = JSON.parse(fs.readFileSync('server.conf'))

export const settings = f => sets[f]
