import zlib from 'zlib'

import AWS from 'aws-sdk'
import CSV from 'csv-parse'

export default class S3 {
  constructor ({ accessKeyId, secretAccessKey }) {
    this._s3 = new AWS.S3({ accessKeyId, secretAccessKey })
  }

  listObjects ({ bucket, prefix }) {
    return new Promise((resolve, reject) => {
      this._s3.listObjects({ Bucket: bucket, Prefix: prefix }, (err, data) => {
        if (err) return reject(err)
        resolve(data.Contents)
      })
    })
  }

  logStream (obj) {
    const stream = this._s3
      .getObject(obj)
      .createReadStream()
      .pipe(zlib.createGunzip())
      .pipe(CSV({
        from_line: 2,
        columns: (header) => header[0].replace('#Fields: ', '').split(' '),
        delimiter: '\t'
      }))

    stream.done = () => new Promise((resolve, reject) => {
      stream.on('error', reject)
      stream.on('end', resolve)
    })

    return stream
  }
}
