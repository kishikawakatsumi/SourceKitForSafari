#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SourceKitServiceProtocol

- (void)sendInitalizeRequestWithContext:(NSDictionary<NSString *, NSString *> *)context
                               resource:(NSString *)resource
                                   slug:(NSString *)slug
                                  reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendInitalizeRequest(context:resource:slug:reply:));

- (void)sendInitializedNotificationWithContext:(NSDictionary<NSString *, NSString *> *)context
                                      resource:(NSString *)resource
                                          slug:(NSString *)slug
                                         reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendInitializedNotification(context:resource:slug:reply:));

- (void)sendDidOpenNotificationWithContext:(NSDictionary<NSString *, NSString *> *)context
                                  resource:(NSString *)resource
                                      slug:(NSString *)slug
                                      path:(NSString *)path
                                      text:(NSString *)text
                                     reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendDidOpenNotification(context:resource:slug:path:text:reply:));

- (void)sendDocumentSymbolRequestWithContext:(NSDictionary<NSString *, NSString *> *)context
                                    resource:(NSString *)resource
                                        slug:(NSString *)slug
                                        path:(NSString *)path
                                       reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendDocumentSymbolRequest(context:resource:slug:path:reply:));

- (void)sendHoverRequestWithContext:(NSDictionary<NSString *, NSString *> *)context
                           resource:(NSString *)resource
                               slug:(NSString *)slug
                               path:(NSString *)path
                               line:(NSInteger)line
                          character:(NSInteger)character
                              reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendHoverRequest(context:resource:slug:path:line:character:reply:));

- (void)sendDefinitionRequestWithContext:(NSDictionary<NSString *, NSString *> *)context
                                resource:(NSString *)resource
                                    slug:(NSString *)slug
                                    path:(NSString *)path
                                    line:(NSInteger)line
                               character:(NSInteger)character
                                   reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendDefinitionRequest(context:resource:slug:path:line:character:reply:));

- (void)sendReferencesRequest:(NSDictionary<NSString *, NSString *> *)context
                     resource:(NSString *)resource
                         slug:(NSString *)slug
                         path:(NSString *)path
                         line:(NSInteger)line
                    character:(NSInteger)character
                        reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendReferencesRequest(context:resource:slug:path:line:character:reply:));

- (void)sendDocumentHighlightRequest:(NSDictionary<NSString *, NSString *> *)context
                            resource:(NSString *)resource
                                slug:(NSString *)slug
                                path:(NSString *)path
                                line:(NSInteger)line
                           character:(NSInteger)character
                               reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendDocumentHighlightRequest(context:resource:slug:path:line:character:reply:));

- (void)sendShutdownRequestWithContext:(NSDictionary<NSString *, NSString *> *)context
                              resource:(NSString *)resource
                                  slug:(NSString *)slug
                                 reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendShutdownRequest(context:resource:slug:reply:));

- (void)sendExitNotificationWithContext:(NSDictionary<NSString *, NSString *> *)context
                               resource:(NSString *)resource
                                   slug:(NSString *)slug
                                  reply:(void (^)(BOOL successfully, NSDictionary<NSString *, id> *response))reply
NS_SWIFT_NAME(sendExitNotification(context:resource:slug:reply:));

- (void)defaultLanguageServerPathWithReply:(void (^)(BOOL successfully, NSString *path))reply
NS_SWIFT_NAME(defaultLanguageServerPath(reply:));

- (void)defaultSDKPathForSDK:(NSString *)SDK reply:(void (^)(BOOL successfully, NSString *path))reply
NS_SWIFT_NAME(defaultSDKPath(for:reply:));

- (void)synchronizeRepository:(NSDictionary<NSString *, NSString *> *)context
                   repository:(NSURL *)repository
             ignoreLastUpdate:(BOOL)ignoreLastUpdate
                        reply:(void (^)(BOOL successfully, NSURL * _Nullable localPath))reply
NS_SWIFT_NAME(synchronizeRepository(context:repository:ignoreLastUpdate:reply:));

- (void)deleteLocalRepository:(NSURL *)repository reply:(void (^)(BOOL successfully, NSURL * _Nullable localPath))reply
NS_SWIFT_NAME(deleteLocalRepository(_:reply:));

- (void)localCheckoutDirectoryFor:(NSURL *)repository reply:(void (^)(BOOL successfully, NSURL * _Nullable localPath))reply
NS_SWIFT_NAME(localCheckoutDirectory(for:reply:));

- (void)showInFinderFor:(NSURL *)path reply:(void (^)(BOOL successfully))reply
NS_SWIFT_NAME(showInFinder(for:reply:));

- (void)lastUpdateFor:(NSURL *)repository reply:(void (^)(BOOL successfully, NSDate * _Nullable modificationDate))reply
NS_SWIFT_NAME(lastUpdate(for:reply:));

@end

NS_ASSUME_NONNULL_END
