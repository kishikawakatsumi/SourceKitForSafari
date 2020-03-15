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

- (void)defaultLanguageServerPathWithReply:(void (^)(BOOL successfully, NSString *path))reply
NS_SWIFT_NAME(defaultLanguageServerPath(reply:));

- (void)defaultSDKPathForSDK:(NSString *)SDK reply:(void (^)(BOOL successfully, NSString *path))reply
NS_SWIFT_NAME(defaultSDKPath(for:reply:));

- (void)synchronizeRepository:(NSURL *)repository force:(BOOL)force reply:(void (^)(BOOL successfully, NSURL * _Nullable localPath))reply
NS_SWIFT_NAME(synchronizeRepository(repository:force:reply:));

- (void)deleteLocalRepository:(NSURL *)repository reply:(void (^)(BOOL successfully, NSURL * _Nullable localPath))reply
NS_SWIFT_NAME(deleteLocalRepository(repository:reply:));

@end

NS_ASSUME_NONNULL_END
