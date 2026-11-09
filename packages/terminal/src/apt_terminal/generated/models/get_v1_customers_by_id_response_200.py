from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1CustomersByIdResponse200")


@_attrs_define
class GetV1CustomersByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        external_id (None | str):
        email (None | str):
        display_name (None | str):
        slug (str):
        avatar_url (str):
        public_profile_enabled (bool):
        profile_visibility (str):
        token_version (int):
        preferred_mfa_method (None | str):
        mfa_failed_attempts (int):
        mfa_locked_until (None | str):
        deleted_at (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['customer'] | Unset):
    """

    id: str
    ecosystem_id: str
    external_id: None | str
    email: None | str
    display_name: None | str
    slug: str
    avatar_url: str
    public_profile_enabled: bool
    profile_visibility: str
    token_version: int
    preferred_mfa_method: None | str
    mfa_failed_attempts: int
    mfa_locked_until: None | str
    deleted_at: None | str
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["customer"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        external_id: None | str
        external_id = self.external_id

        email: None | str
        email = self.email

        display_name: None | str
        display_name = self.display_name

        slug = self.slug

        avatar_url = self.avatar_url

        public_profile_enabled = self.public_profile_enabled

        profile_visibility = self.profile_visibility

        token_version = self.token_version

        preferred_mfa_method: None | str
        preferred_mfa_method = self.preferred_mfa_method

        mfa_failed_attempts = self.mfa_failed_attempts

        mfa_locked_until: None | str
        mfa_locked_until = self.mfa_locked_until

        deleted_at: None | str
        deleted_at = self.deleted_at

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
                "ecosystem_id": ecosystem_id,
                "external_id": external_id,
                "email": email,
                "display_name": display_name,
                "slug": slug,
                "avatar_url": avatar_url,
                "public_profile_enabled": public_profile_enabled,
                "profile_visibility": profile_visibility,
                "token_version": token_version,
                "preferred_mfa_method": preferred_mfa_method,
                "mfa_failed_attempts": mfa_failed_attempts,
                "mfa_locked_until": mfa_locked_until,
                "deleted_at": deleted_at,
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

        ecosystem_id = d.pop("ecosystem_id")

        def _parse_external_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        external_id = _parse_external_id(d.pop("external_id"))

        def _parse_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        email = _parse_email(d.pop("email"))

        def _parse_display_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        display_name = _parse_display_name(d.pop("display_name"))

        slug = d.pop("slug")

        avatar_url = d.pop("avatar_url")

        public_profile_enabled = d.pop("public_profile_enabled")

        profile_visibility = d.pop("profile_visibility")

        token_version = d.pop("token_version")

        def _parse_preferred_mfa_method(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        preferred_mfa_method = _parse_preferred_mfa_method(d.pop("preferred_mfa_method"))

        mfa_failed_attempts = d.pop("mfa_failed_attempts")

        def _parse_mfa_locked_until(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        mfa_locked_until = _parse_mfa_locked_until(d.pop("mfa_locked_until"))

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["customer"] | Unset, d.pop("object", UNSET))
        if object_ != "customer" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'customer', got '{object_}'")

        get_v1_customers_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            external_id=external_id,
            email=email,
            display_name=display_name,
            slug=slug,
            avatar_url=avatar_url,
            public_profile_enabled=public_profile_enabled,
            profile_visibility=profile_visibility,
            token_version=token_version,
            preferred_mfa_method=preferred_mfa_method,
            mfa_failed_attempts=mfa_failed_attempts,
            mfa_locked_until=mfa_locked_until,
            deleted_at=deleted_at,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_customers_by_id_response_200
