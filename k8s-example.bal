import ballerina/http;
import wso2/twitter;
import ballerina/config;
// Add kubernetes package
import ballerinax/kubernetes;

endpoint twitter:Client tw {
   clientId: config:getAsString("clientId"),
   clientSecret: config:getAsString("clientSecret"),
   accessToken: config:getAsString("accessToken"),
   accessTokenSecret: config:getAsString("accessTokenSecret"),
   clientConfig:{}
};

// Now instead of inline {port:9090} bind we create a separate endpoint
// We need this so we can add Kubernetes notation to it and tell the compiler
// to generate a Kubernetes services (expose it to the outside world)
@kubernetes:Service {
 serviceType: "NodePort",
 name: "ballerina-demo"
}
endpoint http:Listener listener {
  port: 9090
};

// Instruct the compiler to generate Kubernetes deployment artifacts
// and a docker image out of this Ballerina service
@kubernetes:Deployment {
 image: "smile0x90/ballerina-k8s-demo",
 name: "ballerina-demo"
}
// Pass our config file into the image
@kubernetes:ConfigMap{
   ballerinaConf: "twitter.toml"
}
@http:ServiceConfig {
  basePath: "/"
}
service<http:Service> hello bind listener {
   @http:ResourceConfig {
       path: "/",
       methods: ["POST"]
   }
   hi (endpoint caller, http:Request request) {
       http:Response res;
       string payload = check request.getTextPayload();

       if (!payload.contains("#ballerina")){payload=payload+" #ballerina";}

       twitter:Status st = check tw->tweet(payload);

       json myJson = {
           text: payload,
           id: st.id,
           agent: "ballerina"
       };

       res.setPayload(untaint myJson);

       _ = caller->respond(res);
   }
}
