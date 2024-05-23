use base64::{decode_config, encode_config, URL_SAFE_NO_PAD};
use ic_cdk::{print, println};
use ic_cdk::api::time;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};


pub struct JWT {
    header: Value,
    payload: Value,
    asecret: String,
}



impl JWT {

    pub fn sign(payload: Value, secret: &str, exp: usize) -> String {
        let mut jwt = JWT::new("HS256", "JWT", secret);
        jwt.set_payload(payload, exp);
        jwt.encode()
    }
    
    
    pub fn verify(token: &str, secret: &str) -> Result<Option<Value>, Box<dyn std::error::Error>> {
        // The number of parts in a JWT: header, payload, and signature HEADER.PAYLOAD.SIGNATURE
        let jwt = JWT::new("HS256", "JWT", secret);
        println!("In verify");  
        const TOKEN_PARTS: usize = 3;
        // The index of the signature in a JWT
        const SIGNATURE_INDEX: usize = 2;
        // Split the token into its constituent parts
        let parts: Vec<&str> = token.split('.').collect();
        println!("In verify Parts {:?}", parts);

        // A valid JWT should have 3 parts: header, payload, and signature
        if parts.len() != TOKEN_PARTS {
            return Err("Invalid token".into());
        }

        let (header_str, payload_str) = jwt.decode_parts(&parts)?;
        println!("In verify Header {:?}", header_str);
        println!("In verify Payload {:?}", payload_str);

        let not_decoded_header = parts[0];
        let not_decoded_payload = parts[1];
        let signature = jwt.calculate_signature(not_decoded_header, not_decoded_payload);
        println!("In verify Signature {:?}", &signature);



        // The signature is the third part of the JWT
        if signature != parts[SIGNATURE_INDEX] {
            print("Signature does not match");
            return Ok(None);
        }
        print("Signature matches");
        let payload = jwt.decode_payload(&payload_str)?;
        println!("Payload: {:?}" , payload);

        if jwt.is_token_expired(&payload)? {
            println!("Token expired");
            return Ok(None);
        }
        println!("Payload {:?}", payload);
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
        // Include the secret in the data to be hashed
        hasher.update(format!("{}.{}.{}", header_str, payload_str, self.asecret));
        let signature = hasher.finalize();
        encode_config(&signature, URL_SAFE_NO_PAD)
    }
    fn decode_payload(&self, payload_str: &str) -> Result<Value, Box<dyn std::error::Error>> {
        serde_json::from_str(payload_str).map_err(|e| e.into())
    }

    fn is_token_expired(&self, payload: &Value) -> Result<bool, Box<dyn std::error::Error>> {
        let exp = payload["exp"].as_i64().ok_or("Invalid exp field")?;

        let now = time() as i64;
        Ok(now > exp)
    }

    
    fn set_payload(&mut self, payload: Value, exp_in_minutes: usize) {
        let mut payload_obj = payload.as_object().unwrap().clone();
        let now = time();
        let exp = now + (exp_in_minutes as u64 * 60 * 1_000_000_000); // convert minutes to nanoseconds
        payload_obj.insert("exp".to_string(), json!(exp));
        self.payload = json!(payload_obj);
    }

    fn new(alg: &str, typ: &str, secret: &str) -> Self {
        println!("In JWT::new");
        let header = json!({
            "alg": alg,
            "typ": typ
        });

        JWT {
            header,
            payload: Value::Null,
            asecret: secret.to_string(),
        }
    }

    fn encode(&self) -> String {
        let header = encode_config(&self.header.to_string().into_bytes(), URL_SAFE_NO_PAD);
        let payload = encode_config(&self.payload.to_string().into_bytes(), URL_SAFE_NO_PAD);

        let mut hasher = Sha256::new();
        hasher.update(format!("{}.{}.{}", header, payload, self.asecret));
        let signature = hasher.finalize();
        let signature = encode_config(&signature, URL_SAFE_NO_PAD);

        format!("{}.{}.{}", header, payload, signature)
    }
}

