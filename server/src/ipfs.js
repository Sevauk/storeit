import ipfs from 'ipfs-api'

// TODO: test me ! =)

const node = ipfs('/ip4/127.0.0.1/tcp/5001')

// TODO: make it work for very big files (about > 50Mo)

// whoops, useless
const readAll = stream => new Promise((resolve, reject) => {

  let content = ''
  stream.on('data', buf => content += buf.toString())
  stream.on('end', () => resolve(content.concat()))
  stream.on('error', err => reject(err))
})

// list every chunk (every link if the file is big) of an ipfs object
export const listChunks = (multihash) =>
  node.id()
    .then(() => node.object.get(multihash))
    .then((res) => {
      if (res.Links.length > 0) { // the file has multiple chunks
        return res.Links.map((e) => e.Hash)
      }
      else {
        return [multihash]
      }
    })
