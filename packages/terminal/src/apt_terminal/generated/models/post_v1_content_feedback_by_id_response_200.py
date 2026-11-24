from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentFeedbackByIdResponse200")


@_attrs_define
class PostV1ContentFeedbackByIdResponse200:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['content.feedback'] | Unset):
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
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["content.feedback"] | Unset = UNSET

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

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "ecosystem_id": ecosystem_id,
                "user_email": user_email,
                "category": category,
                "subject": subject,
                "body": body,
                "platform": platform,
                "app_version": app_version,
                "os_version": os_version,
                "device_info": device_info,
                "status": status,
                "admin_notes": admin_notes,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        ecosystem_id = d.pop("ecosystem_id")

        user_email = d.pop("user_email")

        category = d.pop("category")

        subject = d.pop("subject")

        body = d.pop("body")

        platform = d.pop("platform")

        app_version = d.pop("app_version")

        os_version = d.pop("os_version")

        device_info = d.pop("device_info")

        status = d.pop("status")

        admin_notes = d.pop("admin_notes")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["content.feedback"] | Unset, d.pop("object", UNSET))
        if object_ != "content.feedback" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'content.feedback', got '{object_}'")

        post_v1_content_feedback_by_id_response_200 = cls(
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
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return post_v1_content_feedback_by_id_response_200
