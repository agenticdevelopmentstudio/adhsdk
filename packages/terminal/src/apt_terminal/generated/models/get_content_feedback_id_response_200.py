from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetContentFeedbackIdResponse200")


@_attrs_define
class GetContentFeedbackIdResponse200:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        user_email (str):
        category (str):
        subject (str):
        body (str):
        platform (str):
        app_version (str):
        os_version (str):
        device_info (str):
        status (str):
        admin_notes (str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    user_email: str
    category: str
    subject: str
    body: str
    platform: str
    app_version: str
    os_version: str
    device_info: str
    status: str
    admin_notes: str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        user_email = self.user_email

        category = self.category

        subject = self.subject

        body = self.body

        platform = self.platform

        app_version = self.app_version

        os_version = self.os_version

        device_info = self.device_info

        status = self.status

        admin_notes = self.admin_notes

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "userEmail": user_email,
                "category": category,
                "subject": subject,
                "body": body,
                "platform": platform,
                "appVersion": app_version,
                "osVersion": os_version,
                "deviceInfo": device_info,
                "status": status,
                "adminNotes": admin_notes,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        user_email = d.pop("userEmail")

        category = d.pop("category")

        subject = d.pop("subject")

        body = d.pop("body")

        platform = d.pop("platform")

        app_version = d.pop("appVersion")

        os_version = d.pop("osVersion")

        device_info = d.pop("deviceInfo")

        status = d.pop("status")

        admin_notes = d.pop("adminNotes")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_content_feedback_id_response_200 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            user_email=user_email,
            category=category,
            subject=subject,
            body=body,
            platform=platform,
            app_version=app_version,
            os_version=os_version,
            device_info=device_info,
            status=status,
            admin_notes=admin_notes,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_content_feedback_id_response_200
