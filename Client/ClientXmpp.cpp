#include "ClientXmpp.h"
#include "qxmpp/QXmppMessage.h"
#include "qxmpp/QXmppRosterManager.h"
#include "qxmpp/QXmppConfiguration.h"
#include "qxmpp/QXmppIq.h"
#include "Global/GlobalUserQXmpp.h"
#include "Global/Global.h"
#include "qxmpp/QXmppClient.h"
#include "qxmpp/QXmppVCardManager.h"

CClientXmpp::CClientXmpp(QObject *parent)
    : CClient(parent),
    m_User(NULL)
{
    //初始化qxmpp log
    m_Client.logger()->setLoggingType(QXmppLogger::StdoutLogging);

    m_Client.addExtension(&m_CallManager);
    m_Client.addExtension(&m_MucManager);
    m_Client.addExtension(&m_TransferManager);

    bool check = false;
    check = connect(&m_Client, SIGNAL(error(QXmppClient::Error)),
                    SLOT(slotClientError(QXmppClient::Error)));
    Q_ASSERT(check);

    /*check = connect(m_Client, SIGNAL(iqReceived(QXmppIq)),
                    SLOT(slotClientIqReceived(QXmppIq)));
    Q_ASSERT(check);//*/

    check = connect(&m_Client, SIGNAL(stateChanged(QXmppClient::State)),
                    SLOT(slotStateChanged(QXmppClient::State)));
    Q_ASSERT(check);

    check = connect(&m_Client, SIGNAL(connected()),
                    SIGNAL(sigClientConnected()));
    Q_ASSERT(check);

    check = connect(&m_Client, SIGNAL(disconnected),
                    SIGNAL(sigClientDisconnected()));
    Q_ASSERT(check);
        
    check = connect(&(m_Client.vCardManager()), SIGNAL(clientVCardReceived()),
                    SLOT(slotClientVCardReceived()));
    Q_ASSERT(check);

    check = connect(&m_Client.vCardManager(), SIGNAL(vCardReceived(const QXmppVCardIq&)),
                    SLOT(slotvCardReceived(const QXmppVCardIq&)));
    Q_ASSERT(check);
}

CClientXmpp::~CClientXmpp()
{
}

int CClientXmpp::Login(const QString &szUserName, const QString &szPassword, CUserInfo::USER_INFO_STATUS status)
{
    QXmppConfiguration config;
    //TODO:设置为非sasl验证  
    config.setUseSASLAuthentication(false);
    //config.setUseNonSASLAuthentication(false);
    config.setHost(CGlobal::Instance()->GetXmppServer());
    config.setPort(CGlobal::Instance()->GetXmppServerPort());
    config.setDomain(CGlobal::Instance()->GetXmppDomain());
    config.setUser(szUserName);
    config.setPassword(szPassword);

    QXmppPresence presence;
    presence.setAvailableStatusType(StatusToPresence(status));
    m_Client.connectToServer(config, presence);
}

int CClientXmpp::RequestUserInfoLocale()
{
    int nRet = 0;
    m_Client.vCardManager().requestClientVCard();
    return nRet;
}

int CClientXmpp::RequestUserInfoRoster(const QString& szId)
{
    m_Client.vCardManager().requestVCard(szId);
    return 0;
}

int CClientXmpp::setClientStatus(CUserInfo::USER_INFO_STATUS status)
{
    QXmppPresence presence;
    presence.setAvailableStatusType(StatusToPresence(status));
    m_Client.setClientPresence(presence);
}

QXmppPresence::AvailableStatusType CClientXmpp::StatusToPresence(CUserInfo::USER_INFO_STATUS status)
{
    QXmppPresence::AvailableStatusType s;
    switch (status) {
    case CUserInfo::Online:
        s = QXmppPresence::Online;
        break;
    case CUserInfo::Away:
        s = QXmppPresence::Away;
        break;
    case CUserInfo::Chat:
        s = QXmppPresence::Chat;
        break;
    case CUserInfo::DO_NOT_DISTURB:
        s = QXmppPresence::DND;
        break;
    case CUserInfo::XA:
        s = QXmppPresence::XA;
        break;
    case CUserInfo::Invisible:
    default:
        s = QXmppPresence::Invisible;
        break;
    }
    return s;
}

void CClientXmpp::slotClientError(QXmppClient::Error e)
{
    LOG_MODEL_DEBUG("CClientXmpp", "CClientXmpp:: Error:%d", e);

    ERROR_TYPE error;
    switch (e) {
    case QXmppClient::SocketError:
        error = NetworkError;
        break;
    case QXmppClient::XmppStreamError:
        error = LoginFail;
        break;
    case QXmppClient::KeepAliveError:
        error = KeepAliveError;
    default:
        error = NoError;
        break;
    }
    emit sigClientError(error);
}

void CClientXmpp::slotClientIqReceived(const QXmppIq &iq)
{
    LOG_MODEL_DEBUG("CClientXmpp", "CClientXmpp:: iq Received:%d", iq.error().condition());
}

void CClientXmpp::slotStateChanged(QXmppClient::State state)
{
    LOG_MODEL_DEBUG("CClientXmpp", "CClientXmpp::stateChanged, state:%d", state);

    //TODO:同一账户在不同地方登录。QXMPP没有提供错误状态  

    /*if(e.xmppStreamError().condition()
            == QXmppStanza::Error::Conflict)
    {
        QMessageBox msg(QMessageBox::QMessageBox::Critical,
                        tr("Error"),
                        tr("The user had logined in other place"),
                        QMessageBox::Ok);

        if(NULL == m_pLogin)
            m_pLogin = new CFrmLogin;

        if(m_pLogin)
        {
            this->setCentralWidget(m_pLogin);
        }
    }*/
}

//得到本地用户形象信息  
void CClientXmpp::slotClientVCardReceived()
{
    LOG_MODEL_DEBUG("CClientXmpp", "CClientXmpp::slotClientVCardReceived");
 
    m_User->UpdateUserInfoLocale(m_Client.vCardManager().clientVCard(), 
                               m_Client.vCardManager().clientVCard().to());
    //TODO:是否需要发信号？  
    
}

void CClientXmpp::slotvCardReceived(const QXmppVCardIq&)
{
    
    m_User->UpdateUserInfoLocale(m_Client.vCardManager().clientVCard(), 
                               m_Client.vCardManager().clientVCard().to());
    //TODO:是否需要发信号？  

}
