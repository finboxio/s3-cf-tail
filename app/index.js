import moment from 'moment'
import ms from 'ms'
import Kev from 'kev'
import env from 'envvar'

import fields from 'lib/fields'
import S3 from 'lib/s3'

const LOOKBACK = env.string('LOOKBACK', '7d')

const S3_BUCKET = env.string('S3_BUCKET')
const S3_PREFIX = env.string('S3_PREFIX')
const CF_DISTRIBUTION = env.string('CF_DISTRIBUTION')

const KEV_URL = env.string('KEV_URL')
const KEV_PREFIX = env.string('KEV_PREFIX', [ 's3-cf-tail', S3_BUCKET, S3_PREFIX, CF_DISTRIBUTION ].join(':'))

const AWS_ACCESS_KEY_ID = env.string('AWS_ACCESS_KEY_ID')
const AWS_SECRET_ACCESS_KEY = env.string('AWS_SECRET_ACCESS_KEY')

const s3 = new S3({ accessKeyId: AWS_ACCESS_KEY_ID, secretAccessKey: AWS_SECRET_ACCESS_KEY })
const kev = new Kev({ url: KEV_URL, prefix: KEV_PREFIX })

const run = async () => {
  const previous = await kev.get('lastSeen')
  const oldest = LOOKBACK && moment.utc().subtract(ms(LOOKBACK), 'ms')
  const unix = [ previous, oldest ].filter(Boolean).map((t) => moment.utc(t).unix())
  const start = moment.unix(Math.max(...unix))

  const current = start.clone().subtract(1, 'hour')
  while (current.isBefore(moment.utc().add(1, 'hour'))) {
    const last_seen = await kev.get('lastSeen')
    const prefix = `${S3_PREFIX}${CF_DISTRIBUTION}.${current.utc().format('YYYY-MM-DD-HH')}`

    const objects = await s3.listObjects({ bucket: S3_BUCKET, prefix: prefix })
    const sorted = objects
      .sort((a, b) => new Date(a.LastModified).getTime() - new Date(b.LastModified).getTime())
      .filter((obj) => current.isBefore(moment.utc(obj.LastModified)))
      .filter((obj) => !last_seen || moment.utc(last_seen).isBefore(moment.utc(obj.LastModified)))

    while (sorted.length) {
      const next = sorted.shift()
      const stream = s3.logStream({ Bucket: S3_BUCKET, Key: next.Key })
      stream.on('data', (record) => {
        const timestamp = `${record.date}T${record.time}.000Z`
        const sanitized = { timestamp, cf_log_file: next.Key }
        for (const field in fields) {
          const rename = fields[field]
          if (typeof rename === 'string') {
            sanitized[rename] = record[field]
          } else {
            sanitized[rename.name] = rename.transform(record[field])
          }
        }
        console.log(JSON.stringify(sanitized))
      })
      await stream.done()
      await kev.set('lastSeen', next.LastModified)
    }

    current.add(1, 'hour')
  }
}

run()
  .catch((e) => console.error(e))
  .finally(() => kev.close())
