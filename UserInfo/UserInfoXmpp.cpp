#include "UserInfoXmpp.h"
#include "qxmpp/QXmppUtils.h"
#include "../Global/Global.h"
#include <QImageWriter>
#include <QImageReader>
#include <QBuffer>

CUserInfoXmpp::CUserInfoXmpp(QObject *parent) :
    CUserInfo(parent)
{
}

QString CUserInfoXmpp::GetShowName()
{
    QString szText;
    switch(CGlobal::Instance()->GetRosterShowType())
    {
    case CGlobal::E_ROSTER_SHOW_NICK:
        szText = GetNick();
        if(!szText.isEmpty())
            break;
    case CGlobal::E_ROSTER_SHOW_NAME:
        szText = GetName();
        if(!szText.isEmpty())
            break;
    case CGlobal::E_ROSTER_SHOW_JID:
        szText = GetId();
    default:
        break;
    }
    return szText;
}

QString CUserInfoXmpp::GetName()
{
    if(m_szName.isEmpty())
        return QXmppUtils::jidToUser(GetJid());
    return m_szName;
}

QString CUserInfoXmpp::GetJid()
{
    return m_szJid;
}

QString CUserInfoXmpp::ID()
{
    return QXmppUtils::jidToBareJid(GetJid());
}

QString CUserInfoXmpp::GetDomain()
{
    return QXmppUtils::jidToDomain(GetJid());
}

QString CUserInfoXmpp::GetResource()
{
    return QXmppUtils::jidToResource(GetJid());
}

int CUserInfoXmpp::UpdateUserInfo(const QXmppVCardIq &vCard, QString jid)
{
    if(!vCard.fullName().isEmpty())
        m_szName = vCard.fullName();
    m_szNick = vCard.nickName();
    m_Birthday = vCard.birthday();
    m_szEmail = vCard.email();
    m_szDescription = vCard.description();
    if(!jid.isEmpty())
        m_szJid = jid;

    //保存头像  
    QByteArray photo = vCard.photo();
    QBuffer buffer;
    buffer.setData(photo);
    buffer.open(QIODevice::ReadOnly);
    QImageReader imageReader(&buffer);
    m_imgPhoto = imageReader.read();
    buffer.close();

    //保存头像到本地  
    QImageWriter imageWriter(CGlobal::Instance()->GetFileUserAvatar(ID()), "png");
    if(!imageWriter.write(GetPhoto()))
        LOG_MODEL_ERROR("CUserInfo", "Save avater error, %s", imageWriter.errorString().toStdString().c_str());

    return 0;
}

int CUserInfoXmpp::UpdateUserInfo(const QXmppRosterIq::Item &rosterItem)
{
    m_szJid = rosterItem.bareJid();
    m_Groups = rosterItem.groups();
    m_subscriptionType = FromQxmppSubscriptionType(rosterItem.subscriptionType());
    return 0;
}

CUserInfo::SUBSCRIPTION_TYPE CUserInfoXmpp::FromQxmppSubscriptionType(QXmppRosterIq::Item::SubscriptionType type)
{
    CUserInfo::SUBSCRIPTION_TYPE t;
    switch(type)
    {
    case QXmppRosterIq::Item::Both:
        t = CUserInfo::Both;
        break;
    case QXmppRosterIq::Item::From:
        t = CUserInfo::From;
        break;
    case QXmppRosterIq::Item::NotSet:
        t = CUserInfo::NotSet;
        break;
    case QXmppRosterIq::Item::Remove:
        t = CUserInfo::Remove;
        break;
    case QXmppRosterIq::Item::To:
        t = CUserInfo::To;
        break;
    case QXmppRosterIq::Item::None:
    default:
        t = CUserInfo::None;
        break;
    }
}

QDataStream & operator <<(QDataStream &output, const CUserInfoXmpp &roster)
{
    output << (CUserInfo&)roster;
    output << roster.m_szJid;
    output << roster.m_szName;
    return output;
}

QDataStream & operator >>(QDataStream &input, CUserInfoXmpp &roster)
{
    input >> (CUserInfo&)roster;
    input >> roster.m_szJid;
    input >> roster.m_szName;
    return input;
}
