import ipfs from 'ipfs-api'
import * as fs from 'fs'

let node = null

const co = (onCo) => {
  console.log('connecting to api...')
  node = ipfs('/ip4/127.0.0.1/tcp/5001')
  setTimeout(() => {
    if (onCo) {
      onCo()
    }
  }, 1000);
}

co()

const get = (hash, file, handlerFn) => {

  node.cat(hash, (err, res) => {
    if (err) {
      return co(() => get(hash, file, handlerFn))
    }

    let data = []

    res.on("data", (chunk) => {
      data.push(chunk)
    })

    res.on("end", () => {
      data = Buffer.concat(data)
      fs.writeFile(file, data, null, (err) => {
        if (err) {
          return console.log(err)
        }
        node.add(file, (err) => {
          if (err) {
            console.log(err)
          }
        })
      })
    })
  })
}

get('QmaWiFWgMw88fS7r1z4djpyDAUM5SRJhFY7v2SFcUHjbVF', 'haha.jpg')
