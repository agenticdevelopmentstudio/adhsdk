from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_account_body_profile_visibility import PostV1AccountBodyProfileVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_account_body_appearance import PostV1AccountBodyAppearance
    from ..models.post_v1_account_body_communication_settings import (
        PostV1AccountBodyCommunicationSettings,
    )
    from ..models.post_v1_account_body_privacy import PostV1AccountBodyPrivacy
    from ..models.post_v1_account_body_workspace_prefs import PostV1AccountBodyWorkspacePrefs


T = TypeVar("T", bound="PostV1AccountBody")


@_attrs_define
class PostV1AccountBody:
    """
    Attributes:
        name (str | Unset):
        slug (str | Unset):
        avatar_url (str | Unset):
        public_profile_enabled (bool | Unset):
        profile_visibility (PostV1AccountBodyProfileVisibility | Unset): The principal's page-level profile visibility.
            Supersedes publicProfileEnabled, which is retained during the expand phase and written in parallel.
        privacy (PostV1AccountBodyPrivacy | Unset): Updates `privacy`.
        appearance (PostV1AccountBodyAppearance | Unset): Updates `appearance`.
        communication_settings (PostV1AccountBodyCommunicationSettings | Unset): Updates `communication_settings`.
        workspace_prefs (PostV1AccountBodyWorkspacePrefs | Unset): Updates `workspace_prefs`.
    """

    name: str | Unset = UNSET
    slug: str | Unset = UNSET
    avatar_url: str | Unset = UNSET
    public_profile_enabled: bool | Unset = UNSET
    profile_visibility: PostV1AccountBodyProfileVisibility | Unset = UNSET
    privacy: PostV1AccountBodyPrivacy | Unset = UNSET
    appearance: PostV1AccountBodyAppearance | Unset = UNSET
    communication_settings: PostV1AccountBodyCommunicationSettings | Unset = UNSET
    workspace_prefs: PostV1AccountBodyWorkspacePrefs | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        slug = self.slug

        avatar_url = self.avatar_url

        public_profile_enabled = self.public_profile_enabled

        profile_visibility: str | Unset = UNSET
        if not isinstance(self.profile_visibility, Unset):
            profile_visibility = self.profile_visibility.value

        privacy: dict[str, Any] | Unset = UNSET
        if not isinstance(self.privacy, Unset):
            privacy = self.privacy.to_dict()

        appearance: dict[str, Any] | Unset = UNSET
        if not isinstance(self.appearance, Unset):
            appearance = self.appearance.to_dict()

        communication_settings: dict[str, Any] | Unset = UNSET
        if not isinstance(self.communication_settings, Unset):
            communication_settings = self.communication_settings.to_dict()

        workspace_prefs: dict[str, Any] | Unset = UNSET
        if not isinstance(self.workspace_prefs, Unset):
            workspace_prefs = self.workspace_prefs.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if slug is not UNSET:
            field_dict["slug"] = slug
        if avatar_url is not UNSET:
            field_dict["avatar_url"] = avatar_url
        if public_profile_enabled is not UNSET:
            field_dict["public_profile_enabled"] = public_profile_enabled
        if profile_visibility is not UNSET:
            field_dict["profile_visibility"] = profile_visibility
        if privacy is not UNSET:
            field_dict["privacy"] = privacy
        if appearance is not UNSET:
            field_dict["appearance"] = appearance
        if communication_settings is not UNSET:
            field_dict["communication_settings"] = communication_settings
        if workspace_prefs is not UNSET:
            field_dict["workspace_prefs"] = workspace_prefs

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_account_body_appearance import (
            PostV1AccountBodyAppearance,
        )
        from ..models.post_v1_account_body_communication_settings import (
            PostV1AccountBodyCommunicationSettings,
        )
        from ..models.post_v1_account_body_privacy import PostV1AccountBodyPrivacy
        from ..models.post_v1_account_body_workspace_prefs import (
            PostV1AccountBodyWorkspacePrefs,
        )

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        slug = d.pop("slug", UNSET)

        avatar_url = d.pop("avatar_url", UNSET)

        public_profile_enabled = d.pop("public_profile_enabled", UNSET)

        _profile_visibility = d.pop("profile_visibility", UNSET)
        profile_visibility: PostV1AccountBodyProfileVisibility | Unset
        if isinstance(_profile_visibility, Unset):
            profile_visibility = UNSET
        else:
            profile_visibility = PostV1AccountBodyProfileVisibility(_profile_visibility)

        _privacy = d.pop("privacy", UNSET)
        privacy: PostV1AccountBodyPrivacy | Unset
        if isinstance(_privacy, Unset):
            privacy = UNSET
        else:
            privacy = PostV1AccountBodyPrivacy.from_dict(_privacy)

        _appearance = d.pop("appearance", UNSET)
        appearance: PostV1AccountBodyAppearance | Unset
        if isinstance(_appearance, Unset):
            appearance = UNSET
        else:
            appearance = PostV1AccountBodyAppearance.from_dict(_appearance)

        _communication_settings = d.pop("communication_settings", UNSET)
        communication_settings: PostV1AccountBodyCommunicationSettings | Unset
        if isinstance(_communication_settings, Unset):
            communication_settings = UNSET
        else:
            communication_settings = PostV1AccountBodyCommunicationSettings.from_dict(
                _communication_settings
            )

        _workspace_prefs = d.pop("workspace_prefs", UNSET)
        workspace_prefs: PostV1AccountBodyWorkspacePrefs | Unset
        if isinstance(_workspace_prefs, Unset):
            workspace_prefs = UNSET
        else:
            workspace_prefs = PostV1AccountBodyWorkspacePrefs.from_dict(_workspace_prefs)

        post_v1_account_body = cls(
            name=name,
            slug=slug,
            avatar_url=avatar_url,
            public_profile_enabled=public_profile_enabled,
            profile_visibility=profile_visibility,
            privacy=privacy,
            appearance=appearance,
            communication_settings=communication_settings,
            workspace_prefs=workspace_prefs,
        )

        post_v1_account_body.additional_properties = d
        return post_v1_account_body

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
