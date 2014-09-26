#include "ManagerXmpp.h"

CManagerXmpp::CManagerXmpp() :
    CManager(),
    m_Client(new CClientXmpp),
    m_User(new CGlobalUserQXmpp)
{
    m_Client->SetUser(m_User);
}

QSharedPointer<CClient> CManagerXmpp::GetClient()
{
    return m_Client;
}

QSharedPointer<CManageUserInfo> CManagerXmpp::GetManageUserInfo()
{
    return m_User;
}