//
//  SCSoundCloudConnection.m
//  SoundCloudAPI
//
//  Created by Ullrich Schäfer on 03.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SCSoundCloudConnection.h"

#import "SCSoundCloudAPI.h"

#import "NXOAuth2Connection.h"
#import "NXOAuth2ConnectionDelegate.h"


@interface SCSoundCloudAPI (SCSoundCloudConnectionRetainer)

- (void)keepTrackOfConnection:(SCSoundCloudConnection *)connection;
- (void)forgetConnection:(SCSoundCloudConnection *)connection;

@end


@interface SCSoundCloudConnection () <NXOAuth2ConnectionDelegate>@end

@implementation SCSoundCloudConnection

#pragma mark Lifecycle

+ (SCSoundCloudConnection *)connectionFromSoundCloudAPI:(SCSoundCloudAPI *)theSoundCloudAPI
												request:(NSURLRequest *)request
											oauthClient:(NXOAuth2Client *)oauthClient
												context:(id)context
									 connectionDelegate:(NSObject<SCSoundCloudConnectionDelegate> *)connectionDelegate;
{
	return [[[[self class] alloc] initWithSoundCloudAPI:theSoundCloudAPI request:request oauthClient:oauthClient context:context connectionDelegate:connectionDelegate] autorelease];
}

- (id)initWithSoundCloudAPI:(SCSoundCloudAPI *)theSoundCloudAPI
					request:(NSURLRequest *)request
				oauthClient:(NXOAuth2Client *)oauthClient
					context:(id)context
		 connectionDelegate:(NSObject<SCSoundCloudConnectionDelegate> *)connectionDelegate;

{
	if (self = [super init]) {
		connection = [[NXOAuth2Connection alloc] initWithRequest:request oauthClient:oauthClient delegate:self];
		connection.context = context;
		delegate = connectionDelegate;
		soundCloudAPI = theSoundCloudAPI;
		
		[soundCloudAPI keepTrackOfConnection:self];
	}
	return self;
}

- (void)dealloc;
{
	[connection cancel];
	[connection release];
	[super dealloc];
}


#pragma mark Public

- (void)cancel;
{
	[soundCloudAPI forgetConnection:self];
	[connection cancel];
}

#pragma mark NXOAuth2ConnectionDelegate

- (void)oauthConnection:(NXOAuth2Connection *)aConnection didFinishWithData:(NSData *)data;
{
	NSAssert(aConnection == connection, @"invalid state");
	if ([delegate respondsToSelector:@selector(soundCloudConnection:didFinishWithData:context:)]) {
		[delegate soundCloudConnection:self didFinishWithData:data context:connection.context];
	}
	[soundCloudAPI forgetConnection:self];
}

- (void)oauthConnection:(NXOAuth2Connection *)aConnection didFailWithError:(NSError *)error;
{
	NSAssert(aConnection == connection, @"invalid state");
	if ([delegate respondsToSelector:@selector(soundCloudConnection:didFailWithError:context:)]) {
		[delegate soundCloudConnection:self didFailWithError:error context:connection.context];
	}
	[soundCloudAPI forgetConnection:self];
}

- (void)oauthConnection:(NXOAuth2Connection *)aConnection didReceiveData:(NSData *)data;
{
	NSAssert(aConnection == connection, @"invalid state");
	if ([delegate respondsToSelector:@selector(soundCloudConnection:didReceiveData:context:)]) {
		[delegate soundCloudConnection:self didReceiveData:data context:connection.context];
	}
	if ([delegate respondsToSelector:@selector(soundCloudConnection:didReceiveBytes:total:context:)]) {
		[delegate soundCloudConnection:self didReceiveBytes:connection.data.length total:connection.expectedContentLength context:connection.context];
	}
}

- (void)oauthConnection:(NXOAuth2Connection *)aConnection didSendBytes:(unsigned long long)bytesSend ofTotal:(unsigned long long)bytesTotal;
{
	NSAssert(aConnection == connection, @"invalid state");
	if ([delegate respondsToSelector:@selector(soundCloudConnection:didSendBytes:total:context:)]) {
		[delegate soundCloudConnection:self didSendBytes:bytesSend total:bytesTotal context:connection.context];
	}
}


@end


#pragma mark SCSoundCloudConnectionRetainer

@implementation SCSoundCloudAPI (SCSoundCloudConnectionRetainer)

- (void)keepTrackOfConnection:(SCSoundCloudConnection *)connection;
{
	[apiConnections addObject:connection];
}

- (void)forgetConnection:(SCSoundCloudConnection *)connection;
{
	[apiConnections removeObject:connection];
}

@end
