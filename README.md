# Infomatrix blog

The blog for *Infomatrix* and the personal blog of *@kmandrup*

## Usage

To run it:

```bash
$ npm install
$ npm start
$ open localhost:3000
```

### Mail Config

Add a file `config/mail.config.json` with your Mailgun settings. 

```javascript
{
  "service": "Mailgun",
  "auth": {
    "user": 'kmandrup@sandboxf27ad213161f46f085819214b2053b43.mailgun.org',
    "pass": "secret",
  },
  "debug": true
}
```

### TODO

Try with `"mailgun-js": "^0.6.5"` to use Mailgun API directly!
 
See [mailgun-js](https://www.npmjs.org/package/mailgun-js)