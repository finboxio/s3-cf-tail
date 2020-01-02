/**
 * Cloudfront Log Fields
 *   date
 *   time
 *   x-edge-location
 *   sc-bytes
 *   c-ip
 *   cs-method
 *   cs(Host)
 *   cs-uri-stem
 *   sc-status
 *   cs(Referer)
 *   cs(User-Agent)
 *   cs-uri-query
 *   cs(Cookie)
 *   x-edge-result-type
 *   x-edge-request-id
 *   x-host-header
 *   cs-protocol
 *   cs-bytes
 *   time-taken
 *   x-forwarded-for
 *   ssl-protocol
 *   ssl-cipher
 *   x-edge-response-result-type
 *   cs-protocol-version
 *   fle-status
 *   fle-encrypted-fields
 *   c-port
 *   time-to-first-byte
 *   x-edge-detailed-result-type
 *   sc-content-type
 *   sc-content-len
 *   sc-range-start
 *   sc-range-end
 */

export default {
  'c-ip': 'ip',
  'cs-method': 'method',
  'sc-status': 'status',
  'cs(User-Agent)': 'user_agent',
  'cs(Referer)': 'referrer',
  'x-host-header': 'host',
  'cs-uri-stem': 'path',
  'x-forwarded-for': 'forwarded_for',
  'time-to-first-byte': 'ttfb',
  'x-edge-result-type': 'cache_result_type',
  'x-edge-response-result-type': 'cache_response_result_type',
  'x-edge-detailed-result-type': 'cache_detailed_result_type',
  'x-edge-request-id': 'smplog_trace'
}
