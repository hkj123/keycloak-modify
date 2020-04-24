package org.keycloak.services.listeners;//package org.keycloak.services.listeners;
//
//import com.fasterxml.jackson.databind.ObjectMapper;
//import org.apache.http.HttpResponse;
//import org.apache.http.client.HttpClient;
//import org.apache.http.client.methods.HttpDelete;
//import org.apache.http.client.methods.HttpPost;
//import org.apache.http.client.methods.HttpPut;
//import org.apache.http.entity.StringEntity;
//import org.apache.http.impl.client.HttpClients;
//import org.jboss.logging.Logger;
//
//import javax.servlet.ServletContextEvent;
//import javax.servlet.ServletContextListener;
//import java.io.IOException;
//import java.util.HashMap;
//import java.util.Map;
//import java.util.UUID;
//import java.util.concurrent.ExecutorService;
//import java.util.concurrent.Executors;
//import java.util.concurrent.ScheduledExecutorService;
//import java.util.concurrent.TimeUnit;
//
///**
// * @author <a href="mailto:admin@qloudfin.com">Qloud Admin</a>
// */
//public class QloudDiscoveryListener implements ServletContextListener {
//
//	private static final Logger logger = Logger.getLogger( QloudDiscoveryListener.class );
//	/**
//	 *
//	 */
//	private final static String SERVICE_REGISTER_PATH = "/discovery/services";
//	/**
//	 *
//	 */
//	private final static String SERVICE_DEREGISTER_PATH = "/discovery/services";
//	/**
//	 *
//	 */
//	private final static String SERVICE_HEALTH_CHECK_PATH = "/discovery/check";
//	/**
//	 *
//	 */
//	private final static String configPath;
//	/**
//	 *
//	 */
//	private final static String serviceName;
//	/**
//	 *
//	 */
//	private final static String serviceID;
//	/**
//	 *
//	 */
//	private final static String publicHost;
//	/**
//	 *
//	 */
//	private final static String publicPort;
//	/**
//	 *
//	 */
//	private final static String localHost;
//	/**
//	 *
//	 */
//	private final static String ssl;
//	/**
//	 *
//	 */
//	private final static String kernelUrl;
//	/**
//	 *
//	 */
//	private final static int localPort;
//	/**
//	 *
//	 */
//	private final static String[] tags;
//	/**
//	 *
//	 */
//	private final static ScheduledExecutorService periodicScheduler;
//	/**
//	 *
//	 */
//	private final static ExecutorService executorService;
//
//	static{
//		//
//		configPath = System.getProperty( "jboss.server.config.dir" );
//		serviceName = ( System.getenv( "QLOUD_SERVICE_NAME" ) == null ? "pdp" : System.getenv( "QLOUD_SERVICE_NAME" ) );
//		serviceID = serviceName + "-" + UUID.randomUUID().toString();
//    	publicHost = ( System.getenv( "QLOUD_PUBLICHOST" ) == null ? "qloudpdp.service.sd" : System.getenv( "QLOUD_PUBLICHOST" ) );
//    	publicPort = ( System.getenv( "QLOUD_PUBLICPORT" ) == null ? "80" : System.getenv( "QLOUD_PUBLICPORT" ) );
//    	localHost = ( System.getenv( "QLOUD_LOCALHOST" ) == null ? "qloudpdp" : System.getenv( "QLOUD_LOCALHOST" ) );
//    	ssl = ( System.getenv( "QLOUD_SSL" ) == null ? "false" : System.getenv( "QLOUD_SSL" ) );
//    	kernelUrl = ( System.getenv( "QLOUD_KERNEL_URL" ) == null ? "http://qloudkernel.service.sd" : System.getenv( "QLOUD_KERNEL_URL" ) );
//    	localPort = Boolean.parseBoolean( ssl ) ? 8443 : 8080;
//    	tags = new String[]{"wildfly"};
//    	//
//		periodicScheduler = Executors.newScheduledThreadPool( 1 , runnable -> {
//				Thread thread = new Thread( runnable );
//				thread.setDaemon( true );
//				thread.setName( "PeriodicHealthCheckIn" );
//				return thread;
//			}
//		);
//		//
//		executorService = Executors.newSingleThreadExecutor( runnable -> {
//				Thread thread = new Thread( runnable );
//				thread.setDaemon( true );
//				thread.setName( "HealthCheckIn" );
//				return thread;
//			}
//		);
//	}
//
//	private HttpClient httpClient = HttpClients.createDefault();
//
//    @Override
//    public void contextInitialized(ServletContextEvent sce) {
//    	//TODO test cluster config ....
//    	Map<String,Object> registeration = new HashMap<>();
//    	Map<String,String> meta = new HashMap<>();
//    	Map<String,String> check = new HashMap<>();
//    	//
//    	registeration.put( "Name", serviceName );
//    	registeration.put( "ID", serviceID );
//    	registeration.put( "Address", publicHost );
//    	registeration.put( "Port", publicPort );
//    	registeration.put( "Tags", tags );
//    	//
//    	meta.put( "LocalHost", localHost );
//    	meta.put( "LocalPort", localPort + "" );
//    	meta.put( "Schema", Boolean.parseBoolean( ssl ) ? "https" : "http" );
//    	//
//    	check.put( "TTL", "15s" );
//    	check.put( "DeregisterCriticalServiceAfter", "60m" );
//    	//
//    	registeration.put( "Meta", meta );
//    	registeration.put( "Check", check );
//
//    	//String fileName = configPath + File.separator + "qloud.json";
//    	logger.debugf( "publicHost is %s, publicPort is %s, localhost is %s, ssl is %s, localPort is %s, kernelUrl is %s", publicHost, publicPort, localHost, ssl, localPort, kernelUrl );
//    	//
//    	Map<String, Object> qloudConfig = new HashMap<>();
//    	try{
//    		//TODO how to config client......
//    		//File qloudJson = new File( fileName );
//    		//JsonNode jsonObj = new ObjectMapper().readTree( qloudJson );
//    		//jsonObj.fields().forEachRemaining( e -> qloudConfig.put( e.getKey(), e.getValue().asText() ) );
//    		//initClient( qloudConfig );
//
//    		int code = postRequest( kernelUrl + SERVICE_REGISTER_PATH, registeration );
//    		logger.infof( "registeration code is: %s", code + "" );
//
//    		if ( code == 200 ){
//	    		logger.info( "starting health check in ......." );
//				//
//				periodicScheduler.scheduleAtFixedRate( () -> {
//					logger.debug( "health check in..." );
//					try {
//						executorService.submit( () -> {
//								try{
//									putRequest( kernelUrl + SERVICE_HEALTH_CHECK_PATH + "/" + "pass" + "/" + "service:" + serviceID, new HashMap<String,Object>() );
//								}catch(Exception e){
//									logger.errorf( "CheckIn Error is: %s", e.getMessage() );
//								}
//							}
//						);
//					}
//					catch (Exception e) {
//						logger.error( "\n" , e );
//					}
//			    } ,
//				5 ,
//				10 ,
//				TimeUnit.SECONDS
//				);
//				logger.info( "started health check in..." );
//	    	}
//
//    	}catch(Exception e){
//    		logger.errorf( "Error is: %s", e.getMessage() );
//    	}
//
//
//    }
//
//    @Override
//    public void contextDestroyed(ServletContextEvent sce) {
//    	//
//    	executorService.shutdown();
//		periodicScheduler.shutdown();
//		//
//    	try{
//    		int code = deleteRequest( kernelUrl + SERVICE_DEREGISTER_PATH + "/" + serviceID );
//    		logger.infof( "deregisteration code is: %s", code + "" );
//
//    	}catch(Exception e){
//    		logger.errorf( "Error is: %s", e.getMessage() );
//    	}
//    }
//
//    private int postRequest( String uri, Map<String,Object> data ) throws IOException {
//        HttpPost httpPost = new HttpPost( uri );
//        httpPost.setHeader( "Content-Type","application/json" );
//        httpPost.setEntity( new StringEntity( new ObjectMapper().writeValueAsString( data ), "utf-8" ) );
//
//        HttpResponse response = httpClient.execute( httpPost );
//        httpPost.releaseConnection();
//        return response.getStatusLine().getStatusCode();
//    }
//
//    private int deleteRequest( String uri ) throws IOException {
//        HttpDelete httpDelete = new HttpDelete( uri );
//        httpDelete.setHeader( "Content-Type","application/json" );
//
//        HttpResponse response = httpClient.execute( httpDelete );
//        httpDelete.releaseConnection();
//        return response.getStatusLine().getStatusCode();
//    }
//
//    private int putRequest( String uri, Map<String,Object> data ) throws IOException {
//        HttpPut httpPut = new HttpPut( uri );
//        httpPut.setHeader( "Content-Type","application/json" );
//        httpPut.setEntity( new StringEntity( new ObjectMapper().writeValueAsString( data ), "utf-8" ) );
//
//        HttpResponse response = httpClient.execute( httpPut );
//        httpPut.releaseConnection();
//        return response.getStatusLine().getStatusCode();
//    }
//
//    /*private void initClient(Map<String,Object> config){
//    	logger.tracef( "qloudconfig is %s", config );
//		if (httpClient == null) {
//			long socketTimeout = (long)config.getOrDefault( "timeoutSeconds", 30L );
//			long establishConnectionTimeout = (long)config.getOrDefault( "establish-connection-timeout-millis", -1L );
//			int maxPooledPerRoute = (int)config.getOrDefault( "max-pooled-per-route", 64 );
//			int connectionPoolSize = (int)config.getOrDefault( "connection-pool-size", 1 );
//			long connectionTTL = (long)config.getOrDefault( "connection-ttl-millis", -1L );
//			long maxConnectionIdleTime = (long)config.getOrDefault( "max-connection-idle-time-millis", 900000L );
//			boolean disableCookies = (boolean)config.getOrDefault( "disable-cookies", true );
//			String clientKeystore = (String)config.getOrDefault( "trustStorePath", "truststore" );
//			String clientKeystorePassword = (String)config.getOrDefault( "trustStorePassword", "qloud@2018" );
//			String clientPrivateKeyPassword = (String)config.getOrDefault( "client-key-password", "" );
//
//			boolean disableTrustManager = (boolean)config.getOrDefault( "trustAll", true );
//			//TODO how to config verify host
//			HttpClientBuilder.HostnameVerificationPolicy hostnamePolicy = disableTrustManager ? null
//			    : HttpClientBuilder.HostnameVerificationPolicy.valueOf( "" );
//
//			HttpClientBuilder builder = new HttpClientBuilder();
//
//			builder.socketTimeout( socketTimeout, TimeUnit.MILLISECONDS )
//			    .establishConnectionTimeout( establishConnectionTimeout, TimeUnit.MILLISECONDS )
//			    .maxPooledPerRoute( maxPooledPerRoute )
//			    .connectionPoolSize( connectionPoolSize )
//			    .connectionTTL( connectionTTL, TimeUnit.MILLISECONDS )
//			    .maxConnectionIdleTime( maxConnectionIdleTime, TimeUnit.MILLISECONDS )
//			    .disableCookies( disableCookies );
//
//			//TODO how to config truststore
//			/*if ( disableTrustManager ) {
//			// TODO: is it ok to do away with disabling trust manager?
//			//builder.disableTrustManager();
//			} else {
//				builder.hostnameVerification( hostnamePolicy );
//
//				try {
//				    builder.trustStore( truststoreProvider.getTruststore() );
//				} catch (Exception e) {
//				    throw new RuntimeException("Failed to load truststore", e);
//				}
//			}
//
//			if ( clientKeystore != null ) {
//				clientKeystore = EnvUtil.replace( clientKeystore );
//				try {
//				    KeyStore clientCertKeystore = KeystoreUtil.loadKeyStore( clientKeystore, clientKeystorePassword );
//				    builder.keyStore( clientCertKeystore, clientPrivateKeyPassword );
//				} catch (Exception e) {
//				    throw new RuntimeException("Failed to load keystore", e);
//				}
//			}
//
//			httpClient = builder.build();
//		}
//
//    }*/
//
//}
