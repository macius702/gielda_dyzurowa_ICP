use base64::{decode_config, encode_config, URL_SAFE_NO_PAD};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct JWT {
    header: Value,
    payload: Value,
    secret: String,
}



impl JWT {

    pub fn sign(payload: Value, secret: &str, exp: usize) -> String {
        let mut jwt = JWT::new("HS256", "JWT", secret);
        jwt.set_payload(payload, exp);
        jwt.encode()
    }
    

    pub fn verify(&self, token: &str) -> Result<Option<Value>, Box<dyn std::error::Error>> {
        // The number of parts in a JWT: header, payload, and signature HEADER.PAYLOAD.SIGNATURE
        const TOKEN_PARTS: usize = 3;
        // The index of the signature in a JWT
        const SIGNATURE_INDEX: usize = 2;
        // Split the token into its constituent parts
        let parts: Vec<&str> = token.split('.').collect();

        // A valid JWT should have 3 parts: header, payload, and signature
        if parts.len() != TOKEN_PARTS {
            return Err("Invalid token".into());
        }

        let (header_str, payload_str) = self.decode_parts(&parts)?;
        let signature = self.calculate_signature(&header_str, &payload_str);



        // The signature is the third part of the JWT
        if signature != parts[SIGNATURE_INDEX] {
            return Ok(None);
        }
        let payload = self.decode_payload(&payload_str)?;
        if self.is_token_expired(&payload)? {
            return Ok(None);
        }

        Ok(Some(payload))
    }

    fn decode_parts(&self, parts: &[&str]) -> Result<(String, String), Box<dyn std::error::Error>> {
        let header = decode_config(parts[0], URL_SAFE_NO_PAD).unwrap();
        let payload = decode_config(parts[1], URL_SAFE_NO_PAD).unwrap();

        let header_str = String::from_utf8(header)?;
        let payload_str = String::from_utf8(payload)?;

        Ok((header_str, payload_str))
    }

    fn calculate_signature(&self, header_str: &str, payload_str: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(format!("{}.{}", header_str, payload_str));        
        let signature = hasher.finalize();
        encode_config(&signature, URL_SAFE_NO_PAD)
    }

    fn decode_payload(&self, payload_str: &str) -> Result<Value, Box<dyn std::error::Error>> {
        serde_json::from_str(payload_str).map_err(|e| e.into())
    }

    fn is_token_expired(&self, payload: &Value) -> Result<bool, Box<dyn std::error::Error>> {
        let exp = payload["exp"].as_i64().ok_or("Invalid exp field")?;
        let now = SystemTime::now().duration_since(SystemTime::UNIX_EPOCH)?.as_secs() as i64;
        Ok(now > exp)
    }

    fn new(alg: &str, typ: &str, secret: &str) -> Self {
        let header = json!({
            "alg": alg,
            "typ": typ
        });

        JWT {
            header,
            payload: Value::Null,
            secret: secret.to_string(),
        }
    }

    fn set_payload(&mut self, payload: Value, exp: usize) {
        let mut payload_obj = payload.as_object().unwrap().clone();
        payload_obj.insert("exp".to_string(), json!(exp));
        self.payload = json!(payload_obj);
    }

    fn encode(&self) -> String {
        let header = encode_config(&self.header.to_string().into_bytes(), URL_SAFE_NO_PAD);
        let payload = encode_config(&self.payload.to_string().into_bytes(), URL_SAFE_NO_PAD);

        let mut hasher = Sha256::new();
        hasher.update(format!("{}.{}", header, payload));
        let signature = hasher.finalize();
        let signature = encode_config(&signature, URL_SAFE_NO_PAD);

        format!("{}.{}.{}", header, payload, signature)
    }
}

