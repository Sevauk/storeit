import ipfs from 'ipfs-api'

const node = ipfs('/ip4/127.0.0.1/tcp/5001')

// list every chunk (every link if the file is big) of an ipfs object
const listChunks = (multihash) =>
  node.id()
    .then(() => node.ls(multihash))
    .then((res) => {
      const obj = res.Objects[0]
      if (obj.links.length > 0) { // the file has multiple chunks
        return obj.Links.map((e) => e.Hash)
      }
      else {
        return obj.Hash
      }
    })

listChunks('QmVbXuWy9FFwFehERPW62mcfLJAMkBrtwMnZg4wXVXawzJ')
  .then((res) => console.log(JSON.stringify(res, null, 2)))
  .catch((err) => console.log(err))

setTimeout(() => 0, 1000000)
