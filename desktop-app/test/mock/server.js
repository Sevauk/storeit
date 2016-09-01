import dotenv from 'dotenv'
import WebSocket from 'ws'

dotenv.config()

let wss = new WebSocket.Server({port: process.env.SERVER_PORT})

console.info(`mock-server listening on port ${process.env.SERVER_PORT}`)

wss.on('connection', function connection(ws) {
  console.log('connection')

  ws.on('message', function incoming(message) {
    console.log('received: %s', message)
    ws.send(JSON.stringify({commandUid: 0, message: 'message'}))
  })

  // ws.send(JSON.stringify({command: 'FADD', parameters: {
  //   files: [
  //     {
  //       isDir: true,
  //       path: '/foo',
  //       files: {
  //         'bar1': {
  //           path: 'foo/bar1.txt',
  //           IPFSHash: 'QmSwwAKAWMiMdFrSbv6CspXzgogZpwdGx2gRxL2NfB7fe8',
  //           isDir: false
  //         },
  //         'bar2': {
  //           path: 'foo/bar2.txt',
  //           IPFSHash: 'QmSwwAKAWMiMdFrSbv6CspXzgogZpwdGx2gRxL2NfB7fe8',
  //           isDir: false
  //         }
  //       }
  //     }
  //   ]
  // }}))
  //

  // ws.send(JSON.stringify({command: 'FDEL', parameters: {files: [
  //   '/foo', '/bar'
  // ]}}))

  // ws.send(JSON.stringify({command: 'FMOV', parameters: {
  //   src: '/foo',
  //   dest: '/foobar'
  // }}))
})
